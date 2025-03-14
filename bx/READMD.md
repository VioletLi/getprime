开头增加 
    .type string <: symbol
    .type real <; float

所有 DB 都要引入 .decl，且 attr name 不能加引号
增加 .decl precondition(X:string)

constraint ⊥() 换成 precondition("error")
PK 翻译

单引号 -> 双引号
not -> !


增加以下三条
    .output precondition
    .output s
    .output v


get 和 put 分开
    get：s_ins, s_del, v_ins, v_del, v
    put: v_ins, v_del, s_ins, s_del, s

+si -> si_prime_ins
-si -> si_prime_del
