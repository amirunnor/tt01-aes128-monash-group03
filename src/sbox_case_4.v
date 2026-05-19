/* S-box using all normal bases */
/* case # 4 : [d^16, d], [alpha^8, alpha^2], [Omega^2, Omega] */
/* beta^8 = N^2*alpha^2, N = w^2 */
/* optimized using OR gates and NAND gates */

/* square in GF(2^2), using normal basis [Omega^2,Omega] */
/* inverse is the same as square in GF(2^2), using any normal basis */
module GF_SQ_2 ( 
    input  wire [1:0] A, 
    output wire [1:0] Q 
);
    assign Q = { A[0], A[1] };
endmodule

/* multiply in GF(2^2), shared factors, using normal basis [Omega^2,Omega] */
module GF_MULS_2 ( 
    input  wire [1:0] A, 
    input  wire       ab, 
    input  wire [1:0] B, 
    input  wire       cd, 
    output wire [1:0] Y 
);
    wire abcd, p, q;
    assign abcd = ~(ab & cd); 
    assign p = (~(A[1] & B[1])) ^ abcd;
    assign q = (~(A[0] & B[0])) ^ abcd;
    assign Y = { p, q };
endmodule

/* multiply & scale by N in GF(2^2), shared factors, basis [Omega^2,Omega] */
module GF_MULS_SCL_2 ( 
    input  wire [1:0] A, 
    input  wire       ab, 
    input  wire [1:0] B, 
    input  wire       cd, 
    output wire [1:0] Y 
);
    wire t, p, q;
    assign t = ~(A[0] & B[0]); 
    assign p = (~(ab & cd)) ^ t;
    assign q = (~(A[1] & B[1])) ^ t;
    assign Y = { p, q };
endmodule

/* inverse in GF(2^4)/GF(2^2), using normal basis [alpha^8, alpha^2] */
module GF_INV_4 ( 
    input  wire [3:0] X, 
    output wire [3:0] Y 
);
    wire [1:0] a, b, c, d, p, q;
    wire sa, sb, sd; 
    assign a = X[3:2];
    assign b = X[1:0];
    assign sa = a[1] ^ a[0];
    assign sb = b[1] ^ b[0];

    assign c = { 
        ~(a[1] | b[1]) ^ (~(sa & sb)),
        ~(sa | sb) ^ (~(a[0] & b[0])) 
    };
    GF_SQ_2 dinv( c, d);
    
    assign sd = d[1] ^ d[0];
    GF_MULS_2 pmul(d, sd, b, sb, p);
    GF_MULS_2 qmul(d, sd, a, sa, q);
    assign Y = { p, q };
endmodule

/* multiply in GF(2^4)/GF(2^2), shared factors, basis [alpha^8, alpha^2] */
module GF_MULS_4 ( 
    input  wire [3:0] A, 
    input  wire [1:0] a1, 
    input  wire       Al, 
    input  wire       Ah, 
    input  wire       aa, 
    input  wire [3:0] B, 
    input  wire [1:0] b1, 
    input  wire       Bl, 
    input  wire       Bh, 
    input  wire       bb, 
    output wire [3:0] Q 
);
    wire [1:0] ph, pl, p;
    GF_MULS_2 himul(A[3:2], Ah, B[3:2], Bh, ph);
    GF_MULS_2 lomul(A[1:0], Al, B[1:0], Bl, pl);
    GF_MULS_SCL_2 summul( a1, aa, b1, bb, p);
    assign Q = { (ph ^ p), (pl ^ p) };
endmodule

/* inverse in GF(2^8)/GF(2^4), using normal basis [d^16, d] */
module GF_INV_8 ( 
    input  wire [7:0] X, 
    output wire [7:0] Y 
);
    wire [3:0] a, b, c, d, p, q;
    wire [1:0] sa, sb, sd; 
    wire al, ah, aa, bl, bh, bb, dl, dh, dd; 
    wire c1, c2, c3; 
    assign a = X[7:4];
    assign b = X[3:0];
    assign sa = a[3:2] ^ a[1:0];
    assign sb = b[3:2] ^ b[1:0];
    assign al = a[1] ^ a[0];
    assign ah = a[3] ^ a[2];
    assign aa = sa[1] ^ sa[0];
    assign bl = b[1] ^ b[0];
    assign bh = b[3] ^ b[2];
    assign bb = sb[1] ^ sb[0];
    
    assign c1 = ~(ah & bh);
    assign c2 = ~(sa[0] & sb[0]);
    assign c3 = ~(aa & bb);
    assign c = { 
        (~(sa[0] | sb[0]) ^ (~(a[3] & b[3]))) ^ c1 ^ c3 ,
        (~(sa[1] | sb[1]) ^ (~(a[2] & b[2]))) ^ c1 ^ c2 ,
        (~(al | bl) ^ (~(a[1] & b[1]))) ^ c2 ^ c3 ,
        (~(a[0] | b[0]) ^ (~(al & bl))) ^ (~(sa[1] & sb[1])) ^ c2 
    };
    GF_INV_4 dinv( c, d);

    assign sd = d[3:2] ^ d[1:0];
    assign dl = d[1] ^ d[0];
    assign dh = d[3] ^ d[2];
    assign dd = sd[1] ^ sd[0];
    GF_MULS_4 pmul(d, sd, dl, dh, dd, b, sb, bl, bh, bb, p);
    GF_MULS_4 qmul(d, sd, dl, dh, dd, a, sa, al, ah, aa, q);
    assign Y = { p, q };
endmodule

/* find Sbox in GF(2^8), by Canright Algorithm */
module bSbox ( 
    input  wire [7:0] A, 
    output wire [7:0] Q 
);
    wire [7:0] B, C;
    wire R1, R2, R3, R4, R5, R6, R7, R8, R9;
    wire T1, T2, T3, T4, T5, T6, T7, T8, T9;
    
    /* change basis from GF(2^8) to GF(2^8)/GF(2^4)/GF(2^2) */
    assign R1 = A[7] ^ A[5];
    assign R2 = A[7] ^ A[4];
    assign R3 = A[6] ^ A[0];
    assign R4 = A[5] ^ R3;
    assign R5 = A[4] ^ R4;
    assign R6 = A[3] ^ A[0];
    assign R7 = A[2] ^ R1;
    assign R8 = A[1] ^ R3;
    assign R9 = A[3] ^ R8;
    assign B[7] = R7 ^ R8;
    assign B[6] = R5;
    assign B[5] = A[1] ^ R4;
    assign B[4] = R1 ^ R3;
    assign B[3] = A[1] ^ R2 ^ R6;
    assign B[2] = A[0];
    assign B[1] = R4;
    assign B[0] = A[2] ^ R9;

    GF_INV_8 inv( B, C );

    /* change basis back from GF(2^8)/GF(2^4)/GF(2^2) to GF(2^8) */
    assign T1 = C[7] ^ C[3];
    assign T2 = C[6] ^ C[4];
    assign T3 = C[6] ^ C[0];
    assign T4 = C[5] ^ C[3];
    assign T5 = C[5] ^ T1;
    assign T6 = C[5] ^ C[1];
    assign T7 = C[4] ^ T6;
    assign T8 = C[2] ^ T4;
    assign T9 = C[1] ^ T2;
    assign Q[7] = T4;
    assign Q[6] = ~T1;
    assign Q[5] = ~T3;
    assign Q[4] = T5;
    assign Q[3] = T2 ^ T5;
    assign Q[2] = T3 ^ T8;
    assign Q[1] = ~T7;
    assign Q[0] = ~T9;
endmodule
