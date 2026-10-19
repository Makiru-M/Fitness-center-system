--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases (except postgres and template1)
--

DROP DATABASE fitness_center_db;




--
-- Drop roles
--

DROP ROLE admin_olena;
DROP ROLE boss_ivan;
DROP ROLE client_artem;
DROP ROLE client_denis;
DROP ROLE client_hanna;
DROP ROLE client_igor;
DROP ROLE client_kateryna;
DROP ROLE client_maksym;
DROP ROLE client_nataliya;
DROP ROLE client_olga;
DROP ROLE client_role;
DROP ROLE client_svitlana;
DROP ROLE client_vitaliy;
DROP ROLE coach_0jee4h;
DROP ROLE coach_6ukuuu;
DROP ROLE coach_92y0ld;
DROP ROLE coach_andriy;
DROP ROLE coach_anna;
DROP ROLE coach_dima;
DROP ROLE coach_ftw1uc;
DROP ROLE coach_ipulgx;
DROP ROLE coach_k3v0kc;
DROP ROLE coach_maksym;
DROP ROLE coach_mariya;
DROP ROLE coach_oleg;
DROP ROLE coach_role;
DROP ROLE coach_serg;
DROP ROLE coach_vfifjr;
DROP ROLE coach_y832cv;
DROP ROLE coach_yulia;
DROP ROLE director_role;
DROP ROLE guest;
DROP ROLE guest_user;
DROP ROLE hr_role;
DROP ROLE manager_petro;
DROP ROLE manager_role;
DROP ROLE mgr_8kepol;
DROP ROLE mgr_992hr9;
DROP ROLE mgr_9jbqnk;
DROP ROLE mgr_jeuk6f;
DROP ROLE mgr_kpafh6;
DROP ROLE mgr_lxkote;
DROP ROLE mgr_pexfhz;
DROP ROLE mgr_qb63kp;
DROP ROLE mgr_t_3lkqc;
DROP ROLE postgres;
DROP ROLE unique_8skwz7;
DROP ROLE unique_b95pcv;
DROP ROLE unique_g04nv6;
DROP ROLE unique_kou2un;
DROP ROLE unique_rc0z3k;
DROP ROLE unique_tii9lb;
DROP ROLE user_5bbf05;
DROP ROLE user_7wrgm0;
DROP ROLE user_cbase1;
DROP ROLE user_e0n6y6;
DROP ROLE user_fge9cn;
DROP ROLE user_gy1jjl;
DROP ROLE user_kzjnhu;
DROP ROLE user_n0f0x4;
DROP ROLE user_nosub_4b5ujn;
DROP ROLE user_nosub_8c84t9;
DROP ROLE user_nosub_by6vax;
DROP ROLE user_nosub_epm87x;
DROP ROLE user_nosub_hcdxhs;
DROP ROLE user_nosub_xfynqd;
DROP ROLE user_oleksandr;
DROP ROLE user_pdpbhq;
DROP ROLE user_qmq351;
DROP ROLE user_rt9buu;
DROP ROLE user_vwv3sn;
DROP ROLE usr_mgr_4050;


--
-- Roles
--

CREATE ROLE admin_olena;
ALTER ROLE admin_olena WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:dQ8r5lfM4tx3aWbF72J8eA==$1RJtHAFPQzMrycXaFmsqS0psZ9GWy6NLv4E9h9QI4s8=:VTJ0+poPoLSue0nSv/rzz+d7OuxuQec6TBCVMbBEIq4=';
CREATE ROLE boss_ivan;
ALTER ROLE boss_ivan WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:pnc0TINNfnMi0hIFmJacWA==$G1PY2dRQBQ5OelgluMQwsVn2ehO9hu1lSLvTHm2GQ6s=:rSAT4smBXPYVHQjkb0xOtudxoTIUCI44MAPm9NRQUso=';
CREATE ROLE client_artem;
ALTER ROLE client_artem WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:dSCeC8CET1cWKDywMVYSKg==$oEZbfAmrPqJrdVayCYT6wmL0ZgRRNjf6yqauG/7REZw=:uHG9fb2wsrTq/tWmU5xdVEThdXMtf2aY8phqKEjZBmE=';
CREATE ROLE client_denis;
ALTER ROLE client_denis WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:QfAHb6H2l76dw4uSe9wkDA==$Nq3g9uYYbwoBs7awAVsVECPOVE4VOcIonMS2U6C5oN0=:0ozxfmBSy6tT7PRTdseMTlkGnJvYqeRp+HhefHqhrmw=';
CREATE ROLE client_hanna;
ALTER ROLE client_hanna WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:b1wZIsWnCvyaUhxSbj8yzA==$8V4gFWNlKmc2Cpbmx+26gGR6mM7r8XDSsV0lMHOn5mk=:PC+fF0b7Zgrtd55zqEAkoi+YjloZTiiRCy2bfakAGqE=';
CREATE ROLE client_igor;
ALTER ROLE client_igor WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:JOWA/rM2UvC/iBl3AoBUUw==$8MhkKwjRu8aXxNMM5bdg9ibb0R8q7bb3+WmHcfApTCQ=:tFnqXPxjLc1nSipE0Z/AKwZEzlxum8wMhPO0rKGLP0E=';
CREATE ROLE client_kateryna;
ALTER ROLE client_kateryna WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:sQxiZKQS/h1DVAhqRD7liQ==$qzehqihAB61QxfGTqTZAVXlOtfX+VqIdOH+Fw81DXAQ=:vj8ynRST10KWPNt4ejcFpsq1/fJrZzlcJd04ipCVwZQ=';
CREATE ROLE client_maksym;
ALTER ROLE client_maksym WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:M0TiGFNTU5lMfSjAqfYwng==$kdHgqQCDDfITtbAhY0MXU98AYU6t9xKue1mypoeKLCI=:fY6l4hVAeifoxoC7vlIMVUmGjTmcuRCwr9s2A/N09Qw=';
CREATE ROLE client_nataliya;
ALTER ROLE client_nataliya WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:VkZHPQCUfhixCy8js1KgfA==$4GoeRWPpYVa19eRn7+rR1SKdvjcIdAw44jR5TFJFUik=:Q5WzMi84+fDTg08qC48OQ7Ke+nOeKvRo+1uWxFjwHrs=';
CREATE ROLE client_olga;
ALTER ROLE client_olga WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:k1PPTMl+a0z4qzuGl9Nqig==$Si7X6g7Z6BU/6qUVWiYdHe3iN+zHuDufP4aRNHAUnU0=:Cqwxu1EsNBMfE/tri8LcW9yLGuXeNTnsPa6Pc98CemY=';
CREATE ROLE client_role;
ALTER ROLE client_role WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE client_svitlana;
ALTER ROLE client_svitlana WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:uTzwg4vZoEwT8VTv29usJA==$WCQoaynSYkIa5cmZ5V7/tHAEFZtdRgfzop6+4JvPghE=:toZcvmR7C1JDas6z3nZhm77GDfJkcvN1lO86uzNCF1U=';
CREATE ROLE client_vitaliy;
ALTER ROLE client_vitaliy WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:EGnysbteBNDCvj2y6vWY6A==$kgYKp2R/9wT1D7riR6hpFQPcj/1eU1e4vUPYuFFs1MM=:4I5pFJ9lyg2N4EOR/Iujlz8DR+vid0j7rZ1ElPNtofc=';
CREATE ROLE coach_0jee4h;
ALTER ROLE coach_0jee4h WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:b8i5tZPjnflyKu7yqm8INg==$UfeEHgVlql/9jpeUJZhaCww0VESbO3dEdHz2aBowWvE=:LQQilOGokbti3ovn83lp0T8PDQEDXvKc844fdninFKA=';
CREATE ROLE coach_6ukuuu;
ALTER ROLE coach_6ukuuu WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:eHN30L2E0K71jbT5gMYSCg==$C9Jh/4kyKZNFejKaiIbOCP3/QRLlL1BrKvfAwelwZQw=:bAw6O9/otJ4BuswDdesmR6phKWLI2G1eMcrLyIS+sG4=';
CREATE ROLE coach_92y0ld;
ALTER ROLE coach_92y0ld WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:4daE7jsc/U/H9J/zThPrBg==$SFu0jsiTe1TEwTYsf8VGiZDjMzAJ61Xu5ZjGl/19HKI=:691mwf4OzsOuBDTgGmD/pWBg0Zf1tm+IwBmRaI9hEkQ=';
CREATE ROLE coach_andriy;
ALTER ROLE coach_andriy WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:/060OT6JsZvY9/7GPcYQww==$lusxwNIlmcCFPeCU9vcir7756ZGa9KNITdIrm1h8Vbs=:YcHg2XAjFuv1IhICRO5fPQuldB0FOWZ5uINcaGgMyQc=';
CREATE ROLE coach_anna;
ALTER ROLE coach_anna WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:gdbnLOokMNgslCZBpcxiug==$t3xeXms+8gwAVcoMmYFGEwEEDYqr0JSBq+Jur3Vd9t0=:sypLaDgRzS9Z58Qm6/22s9hsr/PiEvPOU3VCuYeLw+s=';
CREATE ROLE coach_dima;
ALTER ROLE coach_dima WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:7UIWRNKX/JN8/BsFPE82DA==$yyV6aonjjL3dLBj2W+jiresBCfHExr37fg5ClLubPOg=:OdooeI4MWyiBfUGTyfrJOrPbeAyGDQhVBvzvRIce4FE=';
CREATE ROLE coach_ftw1uc;
ALTER ROLE coach_ftw1uc WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:09ZzYfmoRaq8yKUzOi1RRw==$34c+jsRII1SlWRqmmg8Vy5RjbT3r6gnVZ+YLmIX2CBw=:UGbYHzl8XHWHhOtEaweEwK72Yz4cYpL3yazAl+wd6Cg=';
CREATE ROLE coach_ipulgx;
ALTER ROLE coach_ipulgx WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:9BpQHJ2ZGM+IEa+H3QFQCQ==$GIJ7dvGkQ+6P69qTlOwDDMYLIb22GrWD3dtwnCDCtCY=:cgkatSqfizpsvgXXAWvn1sAEXWn6Q+khKKmtUFU9pNs=';
CREATE ROLE coach_k3v0kc;
ALTER ROLE coach_k3v0kc WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:v1cPsTV02iamdF1gUeimQA==$6OpbXXII9OplorybUSMKPNehICxTUoyK5XJBVM+4NzA=:ozpXisiAdL44K2UbkDX9a3VGY8rurDadVohPC9DODqg=';
CREATE ROLE coach_maksym;
ALTER ROLE coach_maksym WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:vXNHKp8MK0glkYtq9neRyg==$Fqcvb+AV8L7JDHDW541cm8oTnp2Ng156q3NbJ7Rr8OY=:HwgMUuvyP4J5RPZNKPW1wd403HKdiYwUolWSo63fZAE=';
CREATE ROLE coach_mariya;
ALTER ROLE coach_mariya WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:MSpL/hF9ajnfNuL66z8iug==$j8mCFt1SFFnChBXQLCh/V6pTrX8zXQwD6LyCUNW5dOg=:9J/3TO+BWM1C+DlKCB86SsjpgOiUikdgdD3OOUA8UNQ=';
CREATE ROLE coach_oleg;
ALTER ROLE coach_oleg WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:BtUZkegGT3et/GTQ7B6mag==$DcQaYcjSFONwxQ9S4R4K0QHVdqIiV50nOTTG6ZU8QCU=:zmRsTIjllevsH820fO1nYhhe58cxv4qhUpKVVkpI+4c=';
CREATE ROLE coach_role;
ALTER ROLE coach_role WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE coach_serg;
ALTER ROLE coach_serg WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:rbGFfz8/XdUE/XF7x2UoBQ==$deq9HWchRMFY1G8SHGhuAEOaO3IqMdt/dcoO/kLrJew=:yhIHOEK6C2JrHR7EQ803lTOL5d1o9rBnQZwNFeeH9kM=';
CREATE ROLE coach_vfifjr;
ALTER ROLE coach_vfifjr WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:szHxQ/Uah9tRALlPIt53rA==$LpwkXVCZ9vCQYVwoOZp18ki1+3in4+I85SV1q45RGvA=:+EYK30O3+aWDwyXse0LJOYYHbrHhRtREO6Umrvg8+qQ=';
CREATE ROLE coach_y832cv;
ALTER ROLE coach_y832cv WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:NsMFW4gx0k2zqeGG6cBtBw==$DypRaUgM2ha9vqDucO69/9U3m1yFIWOToqHwX5KsBSQ=:wJEvthNgnJAopc/pkGaaGfE9S3bywAHlQmskyRkr670=';
CREATE ROLE coach_yulia;
ALTER ROLE coach_yulia WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:7zeiog+m3yqSVMyVzb05vw==$JWv/vTXOhqARk8q9IFeAfgHpStDwFthkechoD1RSuVc=:qO8LZhBoGpuGe0od82Bz8xuVWZdsfSY5ofjGC4U3m2I=';
CREATE ROLE director_role;
ALTER ROLE director_role WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE guest;
ALTER ROLE guest WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE guest_user;
ALTER ROLE guest_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:b9Rw8q3u4n1oP2Tf9vFn9w==$/XsAfE98UhmZ7tqcLnEJYE+o6uOCbmAIXO67x81zYrs=:dCErJeofVpMbxZunpkgXkd600zixMvGK4DcEzJl1Sj8=';
CREATE ROLE hr_role;
ALTER ROLE hr_role WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE manager_petro;
ALTER ROLE manager_petro WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:mRHJWOxO5n6Tw5Pbd5q6HQ==$W9VUkLgDOqD/eGFb97QAhcIx0dwwETry42v0ghJUuFA=:hj40FLwby4BYQOUrNa0C5DDWS5Icl7BwrPb9RD74LsA=';
CREATE ROLE manager_role;
ALTER ROLE manager_role WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE mgr_8kepol;
ALTER ROLE mgr_8kepol WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:WuF6cGf7EzeiIVYs/0vnyA==$w301HFNOdNdargqY1v7ooXhDDQ6lNmsQnRoi0HRtr2w=:lw3jQJP/tiF9wfJ6AMcZUAlxBy81wxNW6wM6tHForiw=';
CREATE ROLE mgr_992hr9;
ALTER ROLE mgr_992hr9 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:/SBSQjEjZUdf872OpdoV+w==$+Hpp8Ysu3Oezg7vheBo244zXvlqJEH4RHE4AmEedaXo=:bBi3GyANIHx0Add4TyO8erERM25zi0cX9TXpNE43i7Q=';
CREATE ROLE mgr_9jbqnk;
ALTER ROLE mgr_9jbqnk WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:1NfZa36n9tt8OibsotKk9w==$XXxlqyK+zGCLpiSTEvSYpWsGx4CwRi13zhQhP5hXxc4=:/tRivshSlwcGnS1bHTWjv+yzb9J2Sk2Mw8psCSgiMXs=';
CREATE ROLE mgr_jeuk6f;
ALTER ROLE mgr_jeuk6f WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:DpMcPL60Poa+C6UrqU6rPg==$63BpnZ2e0aa1oX9dJg0JTXVITd363qYcgkqV55Sf2u4=:FP3rImZ7i6xf6yQ9eP+dEfVN6skVLJcV3phXIfyxtDc=';
CREATE ROLE mgr_kpafh6;
ALTER ROLE mgr_kpafh6 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:gz6PusdC42ag7eAmo476ng==$u93vTsdZnPL8A51lfkdtzVG4AS0lfu34KKv/LQChTOM=:KVibelNDMOsg+uJIobuyQRyl7nNAxEY0wLl1WBlp/vc=';
CREATE ROLE mgr_lxkote;
ALTER ROLE mgr_lxkote WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:fNtYuC24J+rEBPow/Oz8qw==$yKRDAeKjNkU+5vsC3P5ZCojA9E24xnoyGRbanPzi5MA=:rPzk/VrP1CX40255FQI8Vyy7h2X6dpRcpWszvWdgj14=';
CREATE ROLE mgr_pexfhz;
ALTER ROLE mgr_pexfhz WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:ANQL6e/7P8GCfDKMOLrYIg==$JczOAjHddQkN12qeGizQ+Xm5yeeZNKb6Qap97lgWHq8=:mNgXszEdSuk6ClhAoSU9AzhP33nqppKvVE4aHo9a7sI=';
CREATE ROLE mgr_qb63kp;
ALTER ROLE mgr_qb63kp WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:en2dFCRqxbzVgP50IUyMBw==$FtJ2xAa3A3z5w+36fGdJ2Ide7m9ACXwETcGJy1wqb3E=:jei7UIrZt2TY4zi56VgOiU1HQsx2I9AvavbdkNZwr8s=';
CREATE ROLE mgr_t_3lkqc;
ALTER ROLE mgr_t_3lkqc WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:lWcjBqSxinW+KUnKajvv7A==$tk12tDlSTey8hZdpURuCMTjMf28pvqJdQEYGag3b84c=:SjiatuECzWEJ7uE6sqYMCdEVuVcl8/GvDNu1BFcG09I=';
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:8YIA9dkmwNctoZR+oZAlcw==$3RrC6L+QDWSqGX+pqd9UbbUkfYYxODdgIz2X4m5riMI=:l5NUEDHNpoBMcaw/GpiWmm418Y4zs1hLZUKLD2msoxQ=';
CREATE ROLE unique_8skwz7;
ALTER ROLE unique_8skwz7 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:tc95X9QVmrFP4PmNaJR9dw==$8xhMFJqBRvtwEqzQ9OfmCO22gslbFP692v9Agc70c8A=:F3xPU9BlR2Q7Fe7XAYVQltGf/5dWKC9JDmOcK/6C0/w=';
CREATE ROLE unique_b95pcv;
ALTER ROLE unique_b95pcv WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:Abtt+aCVyqESjUzPC86ACg==$5mxR7BZnVwCwpJVSYMIFvSpf77C/eMUc6LqPJalrlrw=:BcmAPNOcMRjQ5wLxcxVGbU9vyeNXp6L8e/35pmmDKm8=';
CREATE ROLE unique_g04nv6;
ALTER ROLE unique_g04nv6 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:RozIDnOne+7svnM9S6HUJw==$77t/6J9LTycS7pulR6+vuP2xBrRYxEMLfZ9e7A7oPxE=:vTZjehkGpWRNLx+LaCw/MbbiuYBMprBthyEwiK7hjYA=';
CREATE ROLE unique_kou2un;
ALTER ROLE unique_kou2un WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:PgTTfD5MigkNm+2be5vWDg==$jrb9jpSeDcIz5vMOJmASQB4DqJVVM+T7bj8YbA+6GCk=:p6FTrX42UaSQlKbGnwh7qO/1QAKnEj4XKqj3ACvAhkc=';
CREATE ROLE unique_rc0z3k;
ALTER ROLE unique_rc0z3k WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:B0yORrSyxYdUf7SbgSXFEw==$9xUDPpyjLWwuWd2KK82VNZ7Si5i3UVqSGvBjvk0nD44=:75guXaYJ+DwQhXkcYz5CQRYfWlPbC4lD2QasuJuYSUw=';
CREATE ROLE unique_tii9lb;
ALTER ROLE unique_tii9lb WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:YaHba1l34tHZe8T++vbXLQ==$31Wy+rRquYa+cWbIOxBTxoQB3WQmJrRsGtLZ52nKw3Y=:XRSyZCmxqgwc06F9U/ZpWhSwi9pR2qepJ7/1HOHmtbw=';
CREATE ROLE user_5bbf05;
ALTER ROLE user_5bbf05 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:i//zU9PTBIsR06K9Mixe1A==$xAlhBW2F9+44wgRLthz2S1Wu1QhjThyq+AQOz4y6Fxo=:mlrXNRcPKfixkrc+VCTTWYNbPs23ef6ATnNtx3TVBZQ=';
CREATE ROLE user_7wrgm0;
ALTER ROLE user_7wrgm0 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:nUFvoSLjcaf5eZYuD9ZKfw==$qqa3yLzaPCyCVGZq9Qlz5zMKJaYB1/jYZXCMlGo9RA8=:F06PX/P/Buj4I7GdtiiqjqmP2UaZPL9EmiMwOnn1srs=';
CREATE ROLE user_cbase1;
ALTER ROLE user_cbase1 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:fRhW91/aDImVYtf/O6+QzQ==$vj5OcyVHYjFrRubVMU9AL1syUesZOk3Pj12MUfiu4Dc=:br5YSKYohttcnSZQPM/LLJRcC6tchkOA+axgIjbkw/Q=';
CREATE ROLE user_e0n6y6;
ALTER ROLE user_e0n6y6 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:XNIJJJLJzz/NFBx8LFh3Hw==$MLreY3Uy+yJXv/w57iuWsEfSi8bDuo20Lu11a/GsbQQ=:A7q4P/NzdBM275DDr78sbHA2Xw7vuWuJVFgYaQc7Nc8=';
CREATE ROLE user_fge9cn;
ALTER ROLE user_fge9cn WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:QtrEOarn29XWfJnkhGp3kQ==$hR9NOu1Rl4eCIdE1aMrIU0hVzCM9cBvSLrVgLtyR0Js=:jDYvxNIY2zFztk6wr0xtdpPXJXg5Nyq6emPSMcKVLTE=';
CREATE ROLE user_gy1jjl;
ALTER ROLE user_gy1jjl WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:p12hFaWvWUJ68AOTHa5bew==$1HTs7nSurL42UsEl8dzirCEerzfG74LcuE8wxU5ij08=:fnJU/b1w7851SrNUHBdhhNeawwHYRVGB8Wmubk0PlvY=';
CREATE ROLE user_kzjnhu;
ALTER ROLE user_kzjnhu WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:GQ116MT2IhWCsKi619/GMA==$YNM2xi+xayPxFUJ1tVvzwMJ2OQ0qit/t4OUaX6DTKvk=:knLyzT6q5hUs+zpoHNnOrFx66Xh39geM/NTQ3Z3mkII=';
CREATE ROLE user_n0f0x4;
ALTER ROLE user_n0f0x4 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:0eUi09q/xv6yXeUDpsY9rQ==$Zy6bo2V5hcvE06wWdrYL8JcdjY6+E//uuxThxF65k4g=:N3rXXTZE++reb+gpaQqxWtCSZ4LCHTFfejIAIU3d/3k=';
CREATE ROLE user_nosub_4b5ujn;
ALTER ROLE user_nosub_4b5ujn WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:BqXk7td7L1dy7D18z6c/+A==$vC/R2wms/fouG9qNvpMF44t4Ooleyyr7wXmpKIdaQRA=:G9P1jQLrkCI4OtLOpP/h91Av1UJB5DLETD5dfKfddUY=';
CREATE ROLE user_nosub_8c84t9;
ALTER ROLE user_nosub_8c84t9 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:6NXbBAxt7xozh4Ww5imgWA==$WbnwKmA/jDh4Dv8si5JhLXrqWzbzLVqOCE9WUD/l64M=:Nx7/TWAKH9ysL8diRWiIlz3GNUQ3lVJYUYZIzzd5zf8=';
CREATE ROLE user_nosub_by6vax;
ALTER ROLE user_nosub_by6vax WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:s486dDTrcQ7iTTkkOUyc+A==$0+yvLukIa/fiqFgy9Qc87oZawhJu32cx4jsbWC0JZ3w=:0wdWqdv/biaDk8Ns/uYQ2KlPpLQRfcKehlOwiO3n8cY=';
CREATE ROLE user_nosub_epm87x;
ALTER ROLE user_nosub_epm87x WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:YseUe/lmnBTA4OLC+Gk37A==$c6thUWWz+lU/NuvOdvm6mvvBvl5QTKrJ5XVltJuZnl8=:NqhVX7sWuu/ccskVi9e7jm/KX9tv2+yKoNLaKyMu/uw=';
CREATE ROLE user_nosub_hcdxhs;
ALTER ROLE user_nosub_hcdxhs WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:hxp1Cd4gdaYnFBxah2ySLA==$WMuCwGHPIE0OoL4Ma78K8R7TmRsgRk4sTqPA9K4tzuc=:DkT1TGgVODbTT9R8Y5pum3IXAwmqdCkD34vd2dsklBU=';
CREATE ROLE user_nosub_xfynqd;
ALTER ROLE user_nosub_xfynqd WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:dQzHieXVcMDd3Q+W0umBRA==$gTnsSbS+M949Yy3t5TuypeuigZyiOtm5u5URIdMlnMs=:bzyaENeC083XgX9vgAPYVaZ0+GVhUq57VhBmmdt8xXQ=';
CREATE ROLE user_oleksandr;
ALTER ROLE user_oleksandr WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:42sAf+V7vBOXgcbfQ5Sz5Q==$vmaVHYOZYV1DSImvvthRZYV5U5y8Raw5KI/eXuSxlRA=:s0PrrOUAXF1UVf1DhInRFeRXB2hI1JIxB5n4HDnVToA=';
CREATE ROLE user_pdpbhq;
ALTER ROLE user_pdpbhq WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:TfOiZeX69EsNh+Ov13SbNA==$wZOGInt/tUPvM9nmueNdI50Dcgetpl48hyhfzy5ruQY=:oq9ixYpzDwh4Bd8hRc9qaz/R7Z8uSV5H0pOKfAJdznM=';
CREATE ROLE user_qmq351;
ALTER ROLE user_qmq351 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:zBVNsx8SC1cv3s1pPdP/Ew==$G1iLFgVdNxVGVyILhvgtP2zFYhBXGJqYzF8nlA5qELg=:PpyqE+Zr3ZsQwf1igeVvyDR867CsnWAID647ZcZSVZI=';
CREATE ROLE user_rt9buu;
ALTER ROLE user_rt9buu WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:LEq6Vt8wZXgPa4EkBhQkjg==$L2BattZqqY6Kwi/XA8Cvl4acpGSJ4IUoBgLDKslTacg=:6G5eq9i783CZ7fViVXPGregUeRjl5Q5k7Sk6ezmoKxY=';
CREATE ROLE user_vwv3sn;
ALTER ROLE user_vwv3sn WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:/cSVrjyIpmuWnRWH1ds6Zg==$NnMqoUd2rgVNcpWCj+fsz0KV/2y5T3hiHVBO6gz7hQA=:meR5gwn9/orTrZLPFG1jZVyJXlExWo7Dha6y5JOz4xs=';
CREATE ROLE usr_mgr_4050;
ALTER ROLE usr_mgr_4050 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:eLfKDbTbxiwIbwiu5QvQ2g==$c+Ys8vcIFgoTIZY3Q4pZP2AMjwAULqghDctSHnlS19E=:7uiAzP7LH42mfj5cjLzzlGqWmaTaqmyseB02LHOy+zI=';

--
-- User Configurations
--


--
-- Role memberships
--

GRANT client_role TO client_artem WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_denis WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_hanna WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_igor WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_kateryna WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_maksym WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_nataliya WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_olga WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_svitlana WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO client_vitaliy WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO unique_8skwz7 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO unique_b95pcv WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO unique_g04nv6 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO unique_kou2un WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO unique_rc0z3k WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_5bbf05 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_7wrgm0 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_e0n6y6 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_fge9cn WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_gy1jjl WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_kzjnhu WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_nosub_8c84t9 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_nosub_by6vax WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_nosub_epm87x WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_nosub_hcdxhs WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_nosub_xfynqd WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_oleksandr WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_pdpbhq WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_qmq351 WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_rt9buu WITH INHERIT TRUE GRANTED BY postgres;
GRANT client_role TO user_vwv3sn WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_0jee4h WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_6ukuuu WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_92y0ld WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_andriy WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_anna WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_dima WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_ftw1uc WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_ipulgx WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_k3v0kc WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_maksym WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_mariya WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_oleg WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_serg WITH INHERIT TRUE GRANTED BY postgres;
GRANT coach_role TO coach_yulia WITH INHERIT TRUE GRANTED BY postgres;
GRANT director_role TO boss_ivan WITH INHERIT TRUE GRANTED BY postgres;
GRANT guest TO guest_user WITH INHERIT TRUE GRANTED BY postgres;
GRANT hr_role TO admin_olena WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO manager_petro WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_8kepol WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_9jbqnk WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_jeuk6f WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_lxkote WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_pexfhz WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_qb63kp WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO mgr_t_3lkqc WITH INHERIT TRUE GRANTED BY postgres;
GRANT manager_role TO usr_mgr_4050 WITH INHERIT TRUE GRANTED BY postgres;






--
-- Databases
--

--
-- Database "template1" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

UPDATE pg_catalog.pg_database SET datistemplate = false WHERE datname = 'template1';
DROP DATABASE template1;
--
-- Name: template1; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE template1 OWNER TO postgres;

\connect template1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE template1; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: template1; Type: DATABASE PROPERTIES; Schema: -; Owner: postgres
--

ALTER DATABASE template1 IS_TEMPLATE = true;


\connect template1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE template1; Type: ACL; Schema: -; Owner: postgres
--

REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- Database "fitness_center_db" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fitness_center_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE fitness_center_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE fitness_center_db OWNER TO postgres;

\connect fitness_center_db

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: activity_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_status AS ENUM (
    'Scheduled',
    'Completed',
    'Cancelled',
    'No-show',
    'Attended'
);


ALTER TYPE public.activity_status OWNER TO postgres;

--
-- Name: check_coach_schedule_conflict(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_coach_schedule_conflict() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_coach_id         INTEGER;
    v_start_time       TIMESTAMP;
    v_end_time         TIMESTAMP;
    v_conflict_found   BOOLEAN := FALSE;
    v_conflict_info    TEXT;
BEGIN
    IF LOWER(TG_TABLE_NAME) = 'personaltrainings' THEN
        IF NEW.TrainingStatus = 'Cancelled' THEN
            RETURN NEW;
        END IF;

        v_coach_id   := NEW.ID_Coach;
        v_start_time := NEW.TrainingDateTime;
        v_end_time   := NEW.TrainingDateTime + INTERVAL '60 minutes';

        SELECT
            TRUE,
            FORMAT('Групове заняття (ID екземпляра: %s, дата: %s, час: %s - %s)',
                   gci.ID_Instance,
                   gci.ClassDate,
                   (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime))::time,
                   (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::time)
        INTO v_conflict_found, v_conflict_info
        FROM GroupClassInstances gci
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        WHERE gst.ID_Coach = v_coach_id
          AND gci.ClassStatus <> 'Cancelled'
          AND v_start_time < (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))
          AND (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime)) < v_end_time
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити індивідуальне тренування: тренер (ID: %) вже зайнятий у цей час. Конфліктна подія: %',
                v_coach_id, v_conflict_info;
        END IF;

    ELSIF LOWER(TG_TABLE_NAME) = 'groupclassinstances' THEN
        IF NEW.ClassStatus = 'Cancelled' THEN
            RETURN NEW;
        END IF;

        SELECT
            gst.ID_Coach,
            NEW.ClassDate + COALESCE(NEW.ClassStartTime, gst.StartTime),
            NEW.ClassDate + COALESCE(NEW.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')
        INTO v_coach_id, v_start_time, v_end_time
        FROM GroupScheduleTemplates gst
        WHERE gst.ID_Template = NEW.ID_Template;

        SELECT
            TRUE,
            FORMAT('Індивідуальне тренування (ID: %s, дата та час: %s - %s)',
                   pt.ID_Personal,
                   pt.TrainingDateTime,
                   (pt.TrainingDateTime + INTERVAL '60 minutes')::time)
        INTO v_conflict_found, v_conflict_info
        FROM PersonalTrainings pt
        WHERE pt.ID_Coach = v_coach_id
          AND pt.TrainingStatus <> 'Cancelled'
          AND pt.TrainingDateTime < v_end_time
          AND (pt.TrainingDateTime + INTERVAL '60 minutes') > v_start_time
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити групове заняття: тренер (ID: %) вже зайнятий у цей час. Конфліктна подія: %',
                v_coach_id, v_conflict_info;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_coach_schedule_conflict() OWNER TO postgres;

--
-- Name: coach_workload_accum(numeric[], integer, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.coach_workload_accum(p_state numeric[], p_coach_id integer, p_duration numeric) RETURNS numeric[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF p_coach_id IS NOT NULL AND p_duration IS NOT NULL AND p_duration > 0 THEN
        p_state[1] := p_state[1] + p_duration;
        p_state[2] := p_state[2] + 1;
    END IF;

    RETURN p_state;
END;
$$;


ALTER FUNCTION public.coach_workload_accum(p_state numeric[], p_coach_id integer, p_duration numeric) OWNER TO postgres;

--
-- Name: coach_workload_combine(numeric[], numeric[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.coach_workload_combine(p_state1 numeric[], p_state2 numeric[]) RETURNS numeric[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF p_state1 IS NULL THEN
        RETURN p_state2;
    END IF;
    IF p_state2 IS NULL THEN
        RETURN p_state1;
    END IF;

    RETURN ARRAY[
        p_state1[1] + p_state2[1],
        p_state1[2] + p_state2[2]
    ];
END;
$$;


ALTER FUNCTION public.coach_workload_combine(p_state1 numeric[], p_state2 numeric[]) OWNER TO postgres;

--
-- Name: coach_workload_final(numeric[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.coach_workload_final(p_state numeric[]) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF p_state IS NULL OR p_state[2] = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(p_state[1] / p_state[2], 2);
END;
$$;


ALTER FUNCTION public.coach_workload_final(p_state numeric[]) OWNER TO postgres;

--
-- Name: get_coach_weekly_schedule(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_coach_weekly_schedule(p_coach_name character varying, p_week_start_date date) RETURNS TABLE(training_date date, day_of_week text, start_time time without time zone, end_time time without time zone, training_type text, activity_name text, hall_name character varying, client_or_details text, training_status character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_coach_id INTEGER;
BEGIN
    SELECT c.ID_Coach INTO v_coach_id
    FROM Coaches c
    JOIN Staff s ON c.ID_Staff = s.ID_Staff
    WHERE LOWER(TRIM(s.FullName)) = LOWER(TRIM(p_coach_name));

    IF v_coach_id IS NULL THEN
        RAISE EXCEPTION 'Тренера з ПІБ "%" не знайдено в базі даних.', p_coach_name;
    END IF;

    RETURN QUERY
    WITH CombinedSchedule AS (
        SELECT
            gci.ClassDate AS training_date,
            CASE EXTRACT(ISODOW FROM gci.ClassDate)
                WHEN 1 THEN 'Понеділок'
                WHEN 2 THEN 'Вівторок'
                WHEN 3 THEN 'Середа'
                WHEN 4 THEN 'Четвер'
                WHEN 5 THEN 'П''ятниця'
                WHEN 6 THEN 'Субота'
                WHEN 7 THEN 'Неділя'
            END AS day_of_week,
            COALESCE(gci.ClassStartTime, gst.StartTime) AS start_time,
            (COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::TIME AS end_time,
            'Групове заняття'::TEXT AS training_type,
            ct.TypeName::TEXT AS activity_name,
            h.HallName AS hall_name,
            FORMAT('Фактична відвідуваність: %s ос.', gci.ActualAttendance)::TEXT AS client_or_details,
            gci.ClassStatus::VARCHAR AS training_status
        FROM GroupClassInstances gci
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
        JOIN Halls h ON gst.ID_Hall = h.ID_Hall
        WHERE gst.ID_Coach = v_coach_id
          AND gci.ClassDate >= p_week_start_date
          AND gci.ClassDate < (p_week_start_date + INTERVAL '7 days')::DATE

        UNION ALL

        SELECT 
            pt.TrainingDateTime::DATE AS training_date,
            CASE EXTRACT(ISODOW FROM pt.TrainingDateTime)
                WHEN 1 THEN 'Понеділок'
                WHEN 2 THEN 'Вівторок'
                WHEN 3 THEN 'Середа'
                WHEN 4 THEN 'Четвер'
                WHEN 5 THEN 'П''ятниця'
                WHEN 6 THEN 'Субота'
                WHEN 7 THEN 'Неділя'
            END AS day_of_week,
            pt.TrainingDateTime::TIME AS start_time,
            (pt.TrainingDateTime + INTERVAL '60 minutes')::TIME AS end_time,
            'Індивідуальне тренування'::TEXT AS training_type,
            'Персональне заняття'::TEXT AS activity_name,
            h.HallName AS hall_name,
            FORMAT('Клієнт: %s (тел: %s)', cl.FullName, cl.Phone)::TEXT AS client_or_details,
            pt.TrainingStatus::VARCHAR AS training_status
        FROM PersonalTrainings pt
        JOIN Halls h ON pt.ID_Hall = h.ID_Hall
        JOIN Sales s ON pt.ID_Sale = s.ID_Sale
        JOIN Clients cl ON s.ID_Client = cl.ID_Client
        WHERE pt.ID_Coach = v_coach_id
          AND pt.TrainingDateTime::DATE >= p_week_start_date
          AND pt.TrainingDateTime::DATE < (p_week_start_date + INTERVAL '7 days')::DATE
    )
    SELECT * 
    FROM CombinedSchedule
    ORDER BY training_date ASC, start_time ASC;
END;
$$;


ALTER FUNCTION public.get_coach_weekly_schedule(p_coach_name character varying, p_week_start_date date) OWNER TO postgres;

--
-- Name: sp_create_client_user(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_create_client_user(p_db_user character varying, p_password character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN
        RAISE EXCEPTION 'Користувач з логіном "%" вже існує в системі.', p_db_user;
    END IF;

    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE client_role', p_db_user, p_password);
END;
$$;


ALTER FUNCTION public.sp_create_client_user(p_db_user character varying, p_password character varying) OWNER TO postgres;

--
-- Name: sp_fire_employee(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_fire_employee(p_staff_id integer, p_fire_date date DEFAULT CURRENT_DATE) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$

DECLARE

    v_db_user VARCHAR;

BEGIN

    SELECT DB_User INTO v_db_user FROM Staff WHERE ID_Staff = p_staff_id;

    IF NOT FOUND THEN

        RAISE EXCEPTION 'Працівника з ID % не знайдено!', p_staff_id;

    END IF;



    UPDATE Staff SET FireDate = p_fire_date WHERE ID_Staff = p_staff_id;



    -- Блокування входу до PostgreSQL

    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_db_user) THEN

        EXECUTE format('ALTER ROLE %I NOLOGIN', v_db_user);

    END IF;

END;

$$;


ALTER FUNCTION public.sp_fire_employee(p_staff_id integer, p_fire_date date) OWNER TO postgres;

--
-- Name: sp_freeze_client_subscription(integer, date, date, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_freeze_client_subscription(IN p_client_sub_id integer, IN p_freeze_start_date date, IN p_freeze_end_date date, IN p_reason character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_freeze_days      INTEGER;
    v_remaining_days   INTEGER;
    v_old_end_date     DATE;
    v_current_status   VARCHAR(20);
    v_sub_exists       BOOLEAN := FALSE;
BEGIN
    v_freeze_days := p_freeze_end_date - p_freeze_start_date;
    IF v_freeze_days <= 0 THEN
        RAISE EXCEPTION 'Дата закінчення заморозки повинна бути пізнішою за дату початку.';
    END IF;

    -- Перевіряємо, що абонемент існує і належить поточному користувачу сесії (SESSION_USER)
    SELECT cs.RemainingFreezingDays, cs.EndDate, cs.CurrentStatus
    INTO v_remaining_days, v_old_end_date, v_current_status
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    JOIN Clients c ON s.ID_Client = c.ID_Client
    WHERE cs.ID_ClientSub = p_client_sub_id 
      AND c.DB_User = SESSION_USER
    FOR UPDATE OF cs;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Активний абонемент не знайдено або він не належить поточному користувачу.';
    END IF;

    IF v_current_status <> 'Active' THEN
        RAISE EXCEPTION 'Заморозити можна лише активний абонемент. Поточний статус: %', v_current_status;
    END IF;

    IF v_remaining_days < v_freeze_days THEN
        RAISE EXCEPTION 'Недостатньо доступних днів заморозки. Залишок: %, запитано: %', v_remaining_days, v_freeze_days;
    END IF;

    -- 1. Фіксуємо запис у журналі заморозок
    INSERT INTO FreezingLogs (ID_ClientSub, FreezeStartDate, FreezeEndDate, Reason)
    VALUES (p_client_sub_id, p_freeze_start_date, p_freeze_end_date, p_reason);

    -- 2. Оновлюємо статус, залишок днів та зсуваємо дату закінчення абонемента
    UPDATE ClientSubscriptions
    SET EndDate = v_old_end_date + (v_freeze_days * INTERVAL '1 day'),
        RemainingFreezingDays = v_remaining_days - v_freeze_days,
        CurrentStatus = 'Frozen'
    WHERE ID_ClientSub = p_client_sub_id;
END;
$$;


ALTER PROCEDURE public.sp_freeze_client_subscription(IN p_client_sub_id integer, IN p_freeze_start_date date, IN p_freeze_end_date date, IN p_reason character varying) OWNER TO postgres;

--
-- Name: sp_unfreeze_client_subscription(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_unfreeze_client_subscription(IN p_client_sub_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_freezing_id       INTEGER;
    v_freeze_start_date DATE;
    v_freeze_end_date   DATE;
    v_current_status    VARCHAR(20);
    v_used_days         INTEGER;
    v_unused_days       INTEGER;
BEGIN
    SELECT cs.CurrentStatus
    INTO v_current_status
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    JOIN Clients c ON s.ID_Client = c.ID_Client
    WHERE cs.ID_ClientSub = p_client_sub_id 
      AND c.DB_User = SESSION_USER
    FOR UPDATE OF cs;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Абонемент не знайдено або він не належить поточному клієнту.';
    END IF;

    IF v_current_status <> 'Frozen' THEN
        RAISE EXCEPTION 'Скасувати заморозку можна лише для замороженого абонемента. Поточний статус: %', v_current_status;
    END IF;

    SELECT ID_Freezing, FreezeStartDate, FreezeEndDate
    INTO v_freezing_id, v_freeze_start_date, v_freeze_end_date
    FROM FreezingLogs
    WHERE ID_ClientSub = p_client_sub_id
    ORDER BY ID_Freezing DESC
    LIMIT 1
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Запис про заморозку для даного абонемента не знайдено.';
    END IF;

    IF CURRENT_DATE > v_freeze_start_date THEN
        v_used_days := CURRENT_DATE - v_freeze_start_date;
        v_unused_days := (v_freeze_end_date - v_freeze_start_date) - v_used_days;
        IF v_unused_days < 0 THEN
            v_unused_days := 0;
        END IF;

        UPDATE FreezingLogs
        SET FreezeEndDate = CURRENT_DATE
        WHERE ID_Freezing = v_freezing_id;
    ELSE
        v_unused_days := v_freeze_end_date - v_freeze_start_date;

        DELETE FROM FreezingLogs
        WHERE ID_Freezing = v_freezing_id;
    END IF;

    UPDATE ClientSubscriptions
    SET RemainingFreezingDays = RemainingFreezingDays + v_unused_days,
        EndDate = EndDate - (v_unused_days * INTERVAL '1 day'),
        CurrentStatus = 'Active'
    WHERE ID_ClientSub = p_client_sub_id;
END;
$$;

ALTER PROCEDURE public.sp_unfreeze_client_subscription(IN p_client_sub_id integer) OWNER TO postgres;

--
-- Name: sp_book_group_class(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_book_group_class(IN p_instance_id integer, IN p_sale_id integer DEFAULT NULL)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_actual_attendance INTEGER;
    v_max_capacity      INTEGER;
    v_class_status      VARCHAR(20);
    v_sale_id           INTEGER;
    v_is_client_user    BOOLEAN;
BEGIN
    SELECT pg_has_role(SESSION_USER, 'client_role', 'MEMBER') INTO v_is_client_user;

    IF v_is_client_user THEN
        IF p_sale_id IS NULL THEN
            SELECT cs.ID_Sale INTO v_sale_id
            FROM ClientSubscriptions cs
            JOIN Sales s ON cs.ID_Sale = s.ID_Sale
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE c.DB_User = SESSION_USER
              AND cs.CurrentStatus = 'Active'
              AND cs.EndDate >= CURRENT_DATE
            ORDER BY cs.EndDate DESC
            LIMIT 1;

            IF v_sale_id IS NULL THEN
                RAISE EXCEPTION 'У вас немає активного абонемента для запису на групове заняття.';
            END IF;
        ELSE
            SELECT s.ID_Sale INTO v_sale_id
            FROM Sales s
            JOIN Clients c ON s.ID_Client = c.ID_Client
            WHERE s.ID_Sale = p_sale_id AND c.DB_User = SESSION_USER;

            IF v_sale_id IS NULL THEN
                RAISE EXCEPTION 'Чек або абонемент не знайдено або він не належить поточному клієнту.';
            END IF;
        END IF;
    ELSE
        IF p_sale_id IS NULL THEN
            RAISE EXCEPTION 'Для оформлення запису співробітником необхідно вказати ID чека (p_sale_id).';
        ELSE
            v_sale_id := p_sale_id;
        END IF;
    END IF;

    -- Перевірка дублікату запису
    IF EXISTS (
        SELECT 1 FROM GroupClassBookings 
        WHERE ID_Instance = p_instance_id 
          AND ID_Sale = v_sale_id 
          AND BookingStatus = 'Scheduled'
    ) THEN
        RAISE EXCEPTION 'Ви вже записані на це групове заняття.';
    END IF;

    -- Точне блокування екземпляра заняття та перевірка місткості
    SELECT gci.ActualAttendance, h.MaxCapacity, gci.ClassStatus
    INTO v_actual_attendance, v_max_capacity, v_class_status
    FROM GroupClassInstances gci
    JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
    JOIN Halls h ON gst.ID_Hall = h.ID_Hall
    WHERE gci.ID_Instance = p_instance_id
    FOR UPDATE OF gci;

    IF v_actual_attendance IS NULL THEN
        RAISE EXCEPTION 'Екземпляр групового заняття (ID: %) не знайдено.', p_instance_id;
    END IF;

    IF v_class_status <> 'Scheduled' THEN
        RAISE EXCEPTION 'Запис неможливий: статус заняття "%".', v_class_status;
    END IF;

    IF v_actual_attendance >= v_max_capacity THEN
        RAISE EXCEPTION 'Вільних місць у залі немає (місткість: % ос., записано: % ос.).', v_max_capacity, v_actual_attendance;
    END IF;

    -- Створення запису бронювання
    INSERT INTO GroupClassBookings (ID_Instance, ID_Sale, BookingStatus)
    VALUES (p_instance_id, v_sale_id, 'Scheduled');

    -- Інкремент лічильника відвідувачів
    UPDATE GroupClassInstances
    SET ActualAttendance = ActualAttendance + 1
    WHERE ID_Instance = p_instance_id;
END;
$$;


ALTER PROCEDURE public.sp_book_group_class(IN p_instance_id integer, IN p_sale_id integer) OWNER TO postgres;

--
-- Name: sp_cancel_group_booking(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_cancel_group_booking(IN p_booking_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_instance_id    INTEGER;
    v_is_client_user BOOLEAN;
BEGIN
    SELECT pg_has_role(SESSION_USER, 'client_role', 'MEMBER') INTO v_is_client_user;
    IF v_is_client_user THEN
        SELECT gcb.ID_Instance INTO v_instance_id
        FROM GroupClassBookings gcb
        JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
        JOIN Clients c ON s.ID_Client = c.ID_Client
        WHERE gcb.ID_Booking = p_booking_id 
          AND gcb.BookingStatus = 'Scheduled'
          AND c.DB_User = SESSION_USER;

        IF v_instance_id IS NULL THEN
            RAISE EXCEPTION 'Активний запис на групове заняття не знайдено або він не належить поточному клієнту.';
        END IF;
    ELSE
        SELECT gcb.ID_Instance INTO v_instance_id
        FROM GroupClassBookings gcb
        WHERE gcb.ID_Booking = p_booking_id 
          AND gcb.BookingStatus = 'Scheduled';

        IF v_instance_id IS NULL THEN
            RAISE EXCEPTION 'Активний запис на групове заняття не знайдено.';
        END IF;
    END IF;

    UPDATE GroupClassBookings 
    SET BookingStatus = 'Cancelled' 
    WHERE ID_Booking = p_booking_id;

    UPDATE GroupClassInstances 
    SET ActualAttendance = GREATEST(ActualAttendance - 1, 0) 
    WHERE ID_Instance = v_instance_id;
END;
$$;


ALTER PROCEDURE public.sp_cancel_group_booking(IN p_booking_id integer) OWNER TO postgres;


--
-- Name: sp_generate_weekly_group_instances(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_generate_weekly_group_instances(IN p_weeks_ahead integer DEFAULT 1)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_monday DATE;
    v_target_date DATE;
    v_weeks INTEGER := COALESCE(p_weeks_ahead, 1);
    gst RECORD;
BEGIN
    IF v_weeks < 0 THEN
        v_weeks := 0;
    END IF;

    -- Визначити понеділок поточного тижня
    v_monday := date_trunc('week', CURRENT_DATE)::DATE;

    -- Для зміщення тижнів w IN 0..v_weeks
    FOR w IN 0..v_weeks LOOP
        FOR gst IN 
            SELECT ID_Template, DayOfWeek, StartTime 
            FROM GroupScheduleTemplates 
            ORDER BY ID_Template 
        LOOP
            v_target_date := v_monday + (w * 7) + (gst.DayOfWeek - 1);
            IF v_target_date >= CURRENT_DATE THEN
                IF NOT EXISTS (
                    SELECT 1 FROM GroupClassInstances 
                    WHERE ID_Template = gst.ID_Template AND ClassDate = v_target_date
                ) THEN
                    INSERT INTO GroupClassInstances (ID_Template, ClassDate, ClassStartTime, ClassStatus, ActualAttendance)
                    VALUES (gst.ID_Template, v_target_date, gst.StartTime, 'Scheduled', 0);
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;


ALTER PROCEDURE public.sp_generate_weekly_group_instances(IN p_weeks_ahead integer) OWNER TO postgres;

--
-- Name: sp_hire_coach(character varying, date, character varying, integer, character varying, character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_hire_coach(p_fullname character varying, p_birthdate date, p_phone character varying, p_spec_id integer, p_db_user character varying, p_password character varying, p_bio text DEFAULT NULL::text) RETURNS TABLE(staff_id integer, coach_id integer, db_username character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$

DECLARE

    v_staff_id INT;

    v_coach_id INT;

    v_pos_id INT;

BEGIN

    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN

        RAISE EXCEPTION 'Користувач % вже існує!', p_db_user;

    END IF;



    -- Створення акаунту тренера

    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE coach_role', p_db_user, p_password);



    -- Посада тренера

    SELECT ID_Position INTO v_pos_id FROM Positions WHERE PositionName ILIKE '%тренер%' ORDER BY ID_Position LIMIT 1;

    IF v_pos_id IS NULL THEN

        RAISE EXCEPTION 'Посаду тренера не знайдено в Positions!';

    END IF;



    -- Вставка у Staff

    INSERT INTO Staff (FullName, BirthDate, Phone, ID_Position, DB_User, HireDate)

    VALUES (p_fullname, p_birthdate, p_phone, v_pos_id, p_db_user, CURRENT_DATE)

    RETURNING ID_Staff INTO v_staff_id;



    -- Вставка у Coaches

    INSERT INTO Coaches (ID_Staff, ID_Spec, Biography)

    VALUES (v_staff_id, p_spec_id, p_bio)

    RETURNING ID_Coach INTO v_coach_id;



    RETURN QUERY SELECT v_staff_id, v_coach_id, p_db_user;

END;

$$;


ALTER FUNCTION public.sp_hire_coach(p_fullname character varying, p_birthdate date, p_phone character varying, p_spec_id integer, p_db_user character varying, p_password character varying, p_bio text) OWNER TO postgres;

--
-- Name: sp_hire_manager(character varying, date, character varying, character varying, character varying, character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_hire_manager(p_fullname character varying, p_birthdate date, p_phone character varying, p_db_user character varying, p_password character varying, p_position_name character varying DEFAULT 'Адміністратор'::character varying, p_hire_date date DEFAULT CURRENT_DATE) RETURNS TABLE(staff_id integer, db_username character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$

DECLARE

    v_staff_id INT;

    v_pos_id INT;

BEGIN

    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN

        RAISE EXCEPTION 'Користувач % вже існує!', p_db_user;

    END IF;



    -- Створення акаунту менеджера

    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE manager_role', p_db_user, p_password);



    SELECT ID_Position INTO v_pos_id FROM Positions WHERE PositionName ILIKE '%' || p_position_name || '%' LIMIT 1;

    IF v_pos_id IS NULL THEN

        SELECT ID_Position INTO v_pos_id FROM Positions LIMIT 1;

    END IF;



    INSERT INTO Staff (FullName, BirthDate, Phone, ID_Position, DB_User, HireDate)

    VALUES (p_fullname, p_birthdate, p_phone, v_pos_id, p_db_user, p_hire_date)

    RETURNING ID_Staff INTO v_staff_id;



    RETURN QUERY SELECT v_staff_id, p_db_user;

END;

$$;


ALTER FUNCTION public.sp_hire_manager(p_fullname character varying, p_birthdate date, p_phone character varying, p_db_user character varying, p_password character varying, p_position_name character varying, p_hire_date date) OWNER TO postgres;

--
-- Name: sp_register_client(character varying, date, character varying, character varying, character varying, character varying, integer, character varying, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_register_client(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying DEFAULT NULL::character varying, p_medical_notes text DEFAULT NULL::text) RETURNS TABLE(client_id integer, db_username character varying, sale_id integer, subscription_id integer, final_price numeric, end_date date)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$

DECLARE

    v_client_id INT;

    v_sale_id INT;

    v_sub_id INT;

    v_base_price DECIMAL(10,2);

    v_discount INT := 0;

    v_promo_id INT := NULL;

    v_final_price DECIMAL(10,2);

    v_duration INT;

    v_max_freeze INT;

    v_end_date DATE;

    v_manager_id INT;

BEGIN

    -- Перевірка унікальності DB_User у системі PostgreSQL

    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN

        RAISE EXCEPTION 'Користувач % вже зареєстрований у системі!', p_db_user;

    END IF;



    -- Створення користувача PostgreSQL з роллю client_role

    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE client_role', p_db_user, p_password);



    -- Додавання профілю клієнта

    INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)

    VALUES (p_fullname, p_birthdate, p_phone, p_gender, p_db_user)

    RETURNING ID_Client INTO v_client_id;



    -- Додавання медичних застережень, якщо вказано

    IF p_medical_notes IS NOT NULL AND length(trim(p_medical_notes)) > 0 THEN

        INSERT INTO MedicalNotes (ID_Client, NotesText)

        VALUES (v_client_id, p_medical_notes);

    END IF;



    -- Перевірка товару/абонемента у прайсі

    SELECT Price INTO v_base_price FROM PriceList WHERE ID_Item = p_item_id;

    IF v_base_price IS NULL THEN

        RAISE EXCEPTION 'Позицію з ID % не знайдено в PriceList!', p_item_id;

    END IF;



    -- Перевірка промокоду

    IF p_promo_code IS NOT NULL AND length(trim(p_promo_code)) > 0 THEN

        SELECT ID_Promo, DiscountPercent INTO v_promo_id, v_discount

        FROM PromoCodes

        WHERE CodeText = p_promo_code AND ExpiryDate >= CURRENT_DATE;

    END IF;



    -- Розрахунок фінальної ціни

    IF v_discount > 0 THEN

        v_final_price := ROUND(v_base_price * (1.0 - (v_discount::NUMERIC / 100.0)), 2);

    ELSE

        v_final_price := v_base_price;

    END IF;



    -- Визначення відповідального менеджера (дефолтний менеджер із персоналу)

    SELECT ID_Staff INTO v_manager_id 

    FROM Staff 

    WHERE ID_Position IN (SELECT ID_Position FROM Positions WHERE PositionName IN ('Адміністратор', 'Менеджер по роботі з клієнтами', 'HR Менеджер'))

    LIMIT 1;



    IF v_manager_id IS NULL THEN

        SELECT ID_Staff INTO v_manager_id FROM Staff LIMIT 1;

    END IF;



    -- Фіксація факту продажу

    INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate)

    VALUES (v_client_id, p_item_id, v_final_price, v_manager_id, CURRENT_TIMESTAMP)

    RETURNING ID_Sale INTO v_sale_id;



    -- Фіксація застосованого промокоду

    IF v_promo_id IS NOT NULL THEN

        INSERT INTO AppliedPromo (ID_Sale, ID_Promo)

        VALUES (v_sale_id, v_promo_id);

    END IF;



    -- Якщо це абонемент (наявний у PriceListSubs), активуємо підписку

    SELECT DurationDays, MaxFreezingDays INTO v_duration, v_max_freeze

    FROM PriceListSubs WHERE ID_Item = p_item_id;



    IF FOUND THEN

        v_end_date := CURRENT_DATE + v_duration;

        INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays)

        VALUES (v_sale_id, CURRENT_DATE, v_end_date, 'Active', v_max_freeze)

        RETURNING ID_ClientSub INTO v_sub_id;

    ELSE

        v_end_date := NULL;

        v_sub_id := NULL;

    END IF;



    RETURN QUERY SELECT v_client_id, p_db_user, v_sale_id, v_sub_id, v_final_price, v_end_date;

END;

$$;


ALTER FUNCTION public.sp_register_client(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying, p_medical_notes text) OWNER TO postgres;

--
-- Name: sp_sell_subscription(character varying, date, character varying, character varying, character varying, character varying, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_sell_subscription(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying DEFAULT NULL::character varying) RETURNS TABLE(client_id integer, db_user character varying, sale_id integer, sub_id integer, paid_price numeric, sub_end_date date)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_client_id INT;
    v_base_price NUMERIC(10,2);
    v_discount INT := 0;
    v_promo_id INT := NULL;
    v_final_price NUMERIC(10,2);
    v_manager_id INT;
    v_sale_id INT;
    v_duration INT;
    v_max_freeze INT;
    v_end_date DATE;
    v_sub_id INT;
BEGIN
    SELECT ID_Client INTO v_client_id FROM Clients WHERE Phone = p_phone;
    IF v_client_id IS NULL THEN
        PERFORM sp_create_client_user(p_db_user, p_password);
        INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)
        VALUES (p_fullname, p_birthdate, p_phone, p_gender, p_db_user)
        RETURNING ID_Client INTO v_client_id;
    END IF;

    SELECT Price INTO v_base_price FROM PriceList WHERE ID_Item = p_item_id;
    IF v_base_price IS NULL THEN
        RAISE EXCEPTION 'Позицію з ID % не знайдено в PriceList!', p_item_id;
    END IF;

    IF p_promo_code IS NOT NULL AND length(trim(p_promo_code)) > 0 THEN
        SELECT ID_Promo, DiscountPercent INTO v_promo_id, v_discount
        FROM PromoCodes
        WHERE CodeText = p_promo_code AND ExpiryDate >= CURRENT_DATE;
    END IF;

    IF v_discount > 0 THEN
        v_final_price := ROUND(v_base_price * (1.0 - (v_discount::NUMERIC / 100.0)), 2);
    ELSE
        v_final_price := v_base_price;
    END IF;

    SELECT ID_Staff INTO v_manager_id 
    FROM Staff 
    WHERE ID_Position IN (SELECT ID_Position FROM Positions WHERE PositionName IN ('Менеджер клієнтів', 'Менеджер по роботі з клієнтами', 'Адміністратор', 'HR Менеджер'))
    ORDER BY ID_Staff
    LIMIT 1;

    IF v_manager_id IS NULL THEN
        SELECT ID_Staff INTO v_manager_id FROM Staff LIMIT 1;
    END IF;

    INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate)
    VALUES (v_client_id, p_item_id, v_final_price, v_manager_id, CURRENT_TIMESTAMP)
    RETURNING ID_Sale INTO v_sale_id;

    IF v_promo_id IS NOT NULL THEN
        INSERT INTO AppliedPromo (ID_Sale, ID_Promo)
        VALUES (v_sale_id, v_promo_id);
    END IF;

    SELECT DurationDays, MaxFreezingDays INTO v_duration, v_max_freeze
    FROM PriceListSubs WHERE ID_Item = p_item_id;

    IF FOUND THEN
        v_end_date := CURRENT_DATE + v_duration;
        INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays)
        VALUES (v_sale_id, CURRENT_DATE, v_end_date, 'Active', v_max_freeze)
        RETURNING ID_ClientSub INTO v_sub_id;
    ELSE
        v_end_date := NULL;
        v_sub_id := NULL;
    END IF;

    RETURN QUERY SELECT v_client_id, p_db_user, v_sale_id, v_sub_id, v_final_price, v_end_date;
END;
$$;


ALTER FUNCTION public.sp_sell_subscription(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying) OWNER TO postgres;

--
-- Name: avg_coach_workload(integer, numeric); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.avg_coach_workload(integer, numeric) (
    SFUNC = public.coach_workload_accum,
    STYPE = numeric[],
    INITCOND = '{0, 0}',
    FINALFUNC = public.coach_workload_final
);


ALTER AGGREGATE public.avg_coach_workload(integer, numeric) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: appliedpromo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appliedpromo (
    id_sale integer NOT NULL,
    id_promo integer NOT NULL
);


ALTER TABLE public.appliedpromo OWNER TO postgres;

--
-- Name: classtypes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classtypes (
    id_classtype integer NOT NULL,
    typename character varying(50) NOT NULL
);


ALTER TABLE public.classtypes OWNER TO postgres;

--
-- Name: classtypes_id_classtype_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.classtypes_id_classtype_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classtypes_id_classtype_seq OWNER TO postgres;

--
-- Name: classtypes_id_classtype_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.classtypes_id_classtype_seq OWNED BY public.classtypes.id_classtype;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    id_client integer NOT NULL,
    fullname character varying(100) NOT NULL,
    birthdate date NOT NULL,
    phone character varying(15) NOT NULL,
    gender character varying(10) NOT NULL,
    db_user character varying(32) NOT NULL,
    CONSTRAINT clients_gender_check CHECK (((gender)::text = ANY (ARRAY[('Male'::character varying)::text, ('Female'::character varying)::text, ('Other'::character varying)::text])))
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- Name: clients_id_client_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clients_id_client_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clients_id_client_seq OWNER TO postgres;

--
-- Name: clients_id_client_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clients_id_client_seq OWNED BY public.clients.id_client;


--
-- Name: clientsubscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientsubscriptions (
    id_clientsub integer NOT NULL,
    id_sale integer NOT NULL,
    startdate date DEFAULT CURRENT_DATE NOT NULL,
    enddate date NOT NULL,
    currentstatus character varying(15) DEFAULT 'Active'::character varying NOT NULL,
    remainingfreezingdays integer NOT NULL,
    CONSTRAINT clientsubscriptions_check CHECK ((enddate >= startdate)),
    CONSTRAINT clientsubscriptions_currentstatus_check CHECK (((currentstatus)::text = ANY (ARRAY[('Active'::character varying)::text, ('Frozen'::character varying)::text, ('Expired'::character varying)::text]))),
    CONSTRAINT clientsubscriptions_remainingfreezingdays_check CHECK ((remainingfreezingdays >= 0))
);


ALTER TABLE public.clientsubscriptions OWNER TO postgres;

--
-- Name: clientsubscriptions_id_clientsub_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clientsubscriptions_id_clientsub_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clientsubscriptions_id_clientsub_seq OWNER TO postgres;

--
-- Name: clientsubscriptions_id_clientsub_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clientsubscriptions_id_clientsub_seq OWNED BY public.clientsubscriptions.id_clientsub;


--
-- Name: coaches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.coaches (
    id_coach integer NOT NULL,
    id_staff integer NOT NULL,
    id_spec integer NOT NULL,
    biography text
);


ALTER TABLE public.coaches OWNER TO postgres;

--
-- Name: coaches_id_coach_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.coaches_id_coach_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coaches_id_coach_seq OWNER TO postgres;

--
-- Name: coaches_id_coach_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.coaches_id_coach_seq OWNED BY public.coaches.id_coach;


--
-- Name: freezinglogs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.freezinglogs (
    id_freezing integer NOT NULL,
    id_clientsub integer NOT NULL,
    freezestartdate date DEFAULT CURRENT_DATE NOT NULL,
    freezeenddate date NOT NULL,
    reason text NOT NULL,
    CONSTRAINT freezinglogs_check CHECK ((freezeenddate > freezestartdate))
);


ALTER TABLE public.freezinglogs OWNER TO postgres;

--
-- Name: freezinglogs_id_freezing_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.freezinglogs_id_freezing_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.freezinglogs_id_freezing_seq OWNER TO postgres;

--
-- Name: freezinglogs_id_freezing_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.freezinglogs_id_freezing_seq OWNED BY public.freezinglogs.id_freezing;


--
-- Name: groupclassbookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groupclassbookings (
    id_booking integer NOT NULL,
    id_instance integer NOT NULL,
    id_sale integer NOT NULL,
    bookingstatus public.activity_status DEFAULT 'Scheduled'::public.activity_status NOT NULL
);


ALTER TABLE public.groupclassbookings OWNER TO postgres;

--
-- Name: groupclassbookings_id_booking_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.groupclassbookings_id_booking_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.groupclassbookings_id_booking_seq OWNER TO postgres;

--
-- Name: groupclassbookings_id_booking_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.groupclassbookings_id_booking_seq OWNED BY public.groupclassbookings.id_booking;


--
-- Name: groupclassinstances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groupclassinstances (
    id_instance integer NOT NULL,
    id_template integer NOT NULL,
    classdate date NOT NULL,
    classstatus public.activity_status DEFAULT 'Scheduled'::public.activity_status NOT NULL,
    actualattendance integer DEFAULT 0 NOT NULL,
    classstarttime time without time zone,
    CONSTRAINT groupclassinstances_actualattendance_check CHECK ((actualattendance >= 0))
);


ALTER TABLE public.groupclassinstances OWNER TO postgres;

--
-- Name: groupclassinstances_id_instance_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.groupclassinstances_id_instance_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.groupclassinstances_id_instance_seq OWNER TO postgres;

--
-- Name: groupclassinstances_id_instance_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.groupclassinstances_id_instance_seq OWNED BY public.groupclassinstances.id_instance;


--
-- Name: groupscheduletemplates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groupscheduletemplates (
    id_template integer NOT NULL,
    id_classtype integer NOT NULL,
    dayofweek integer NOT NULL,
    starttime time without time zone NOT NULL,
    durationminutes integer NOT NULL,
    id_hall integer NOT NULL,
    id_coach integer NOT NULL,
    CONSTRAINT groupscheduletemplates_dayofweek_check CHECK (((dayofweek >= 1) AND (dayofweek <= 7))),
    CONSTRAINT groupscheduletemplates_durationminutes_check CHECK ((durationminutes > 0))
);


ALTER TABLE public.groupscheduletemplates OWNER TO postgres;

--
-- Name: groupscheduletemplates_id_template_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.groupscheduletemplates_id_template_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.groupscheduletemplates_id_template_seq OWNER TO postgres;

--
-- Name: groupscheduletemplates_id_template_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.groupscheduletemplates_id_template_seq OWNED BY public.groupscheduletemplates.id_template;


--
-- Name: halls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.halls (
    id_hall integer NOT NULL,
    hallname character varying(50) NOT NULL,
    maxcapacity integer NOT NULL,
    isactive boolean DEFAULT true,
    CONSTRAINT halls_maxcapacity_check CHECK ((maxcapacity > 0))
);


ALTER TABLE public.halls OWNER TO postgres;

--
-- Name: halls_id_hall_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.halls_id_hall_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.halls_id_hall_seq OWNER TO postgres;

--
-- Name: halls_id_hall_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.halls_id_hall_seq OWNED BY public.halls.id_hall;


--
-- Name: medicalnotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicalnotes (
    id_client integer NOT NULL,
    notestext text NOT NULL
);


ALTER TABLE public.medicalnotes OWNER TO postgres;

--
-- Name: personaltrainings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personaltrainings (
    id_personal integer NOT NULL,
    id_coach integer NOT NULL,
    id_hall integer NOT NULL,
    id_sale integer NOT NULL,
    trainingdatetime timestamp without time zone NOT NULL,
    trainingstatus public.activity_status DEFAULT 'Scheduled'::public.activity_status NOT NULL
);


ALTER TABLE public.personaltrainings OWNER TO postgres;

--
-- Name: personaltrainings_id_personal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personaltrainings_id_personal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personaltrainings_id_personal_seq OWNER TO postgres;

--
-- Name: personaltrainings_id_personal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personaltrainings_id_personal_seq OWNED BY public.personaltrainings.id_personal;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.positions (
    id_position integer NOT NULL,
    positionname character varying(50) NOT NULL
);


ALTER TABLE public.positions OWNER TO postgres;

--
-- Name: positions_id_position_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.positions_id_position_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.positions_id_position_seq OWNER TO postgres;

--
-- Name: positions_id_position_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.positions_id_position_seq OWNED BY public.positions.id_position;


--
-- Name: pricelist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pricelist (
    id_item integer NOT NULL,
    itemname character varying(100) NOT NULL,
    category character varying(30) NOT NULL,
    price numeric(10,2) NOT NULL,
    pricestartdate date DEFAULT CURRENT_DATE NOT NULL,
    description text,
    CONSTRAINT pricelist_category_check CHECK (((category)::text = ANY (ARRAY[('Membership'::character varying)::text, ('Personal training'::character varying)::text, ('Group training'::character varying)::text, ('Extra'::character varying)::text]))),
    CONSTRAINT pricelist_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.pricelist OWNER TO postgres;

--
-- Name: pricelist_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pricelist_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pricelist_id_item_seq OWNER TO postgres;

--
-- Name: pricelist_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pricelist_id_item_seq OWNED BY public.pricelist.id_item;


--
-- Name: pricelistsubs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pricelistsubs (
    id_item integer NOT NULL,
    durationdays integer NOT NULL,
    maxfreezingdays integer DEFAULT 0 NOT NULL,
    CONSTRAINT pricelistsubs_durationdays_check CHECK ((durationdays > 0)),
    CONSTRAINT pricelistsubs_maxfreezingdays_check CHECK ((maxfreezingdays >= 0))
);


ALTER TABLE public.pricelistsubs OWNER TO postgres;

--
-- Name: promocodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promocodes (
    id_promo integer NOT NULL,
    codetext character varying(20) NOT NULL,
    discountpercent integer NOT NULL,
    expirydate date NOT NULL,
    CONSTRAINT promocodes_discountpercent_check CHECK (((discountpercent >= 1) AND (discountpercent <= 100)))
);


ALTER TABLE public.promocodes OWNER TO postgres;

--
-- Name: promocodes_id_promo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.promocodes_id_promo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.promocodes_id_promo_seq OWNER TO postgres;

--
-- Name: promocodes_id_promo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.promocodes_id_promo_seq OWNED BY public.promocodes.id_promo;


--
-- Name: pt_changelog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pt_changelog (
    id_ptlog integer NOT NULL,
    id_personal integer NOT NULL,
    requesttype character varying(15) NOT NULL,
    reason text NOT NULL,
    changeinitiator character varying(10) NOT NULL,
    changetimestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pt_changelog_changeinitiator_check CHECK (((changeinitiator)::text = ANY (ARRAY[('Client'::character varying)::text, ('Coach'::character varying)::text, ('Manager'::character varying)::text]))),
    CONSTRAINT pt_changelog_requesttype_check CHECK (((requesttype)::text = ANY (ARRAY[('Reschedule'::character varying)::text, ('Cancel'::character varying)::text])))
);


ALTER TABLE public.pt_changelog OWNER TO postgres;

--
-- Name: pt_changelog_id_ptlog_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pt_changelog_id_ptlog_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pt_changelog_id_ptlog_seq OWNER TO postgres;

--
-- Name: pt_changelog_id_ptlog_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pt_changelog_id_ptlog_seq OWNED BY public.pt_changelog.id_ptlog;


--
-- Name: pt_timechangedetails; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pt_timechangedetails (
    id_ptlog integer NOT NULL,
    olddatetime timestamp without time zone NOT NULL,
    newdatetime timestamp without time zone NOT NULL,
    CONSTRAINT pt_timechangedetails_check CHECK ((newdatetime <> olddatetime))
);


ALTER TABLE public.pt_timechangedetails OWNER TO postgres;

--
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales (
    id_sale integer NOT NULL,
    id_client integer NOT NULL,
    id_item integer NOT NULL,
    saledate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_manager integer NOT NULL,
    saleprice numeric(10,2) NOT NULL,
    CONSTRAINT sales_saleprice_check CHECK ((saleprice >= (0)::numeric))
);


ALTER TABLE public.sales OWNER TO postgres;

--
-- Name: sales_id_sale_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sales_id_sale_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_id_sale_seq OWNER TO postgres;

--
-- Name: sales_id_sale_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sales_id_sale_seq OWNED BY public.sales.id_sale;


--
-- Name: specializations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specializations (
    id_spec integer NOT NULL,
    specname character varying(50) NOT NULL
);


ALTER TABLE public.specializations OWNER TO postgres;

--
-- Name: specializations_id_spec_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.specializations_id_spec_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.specializations_id_spec_seq OWNER TO postgres;

--
-- Name: specializations_id_spec_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.specializations_id_spec_seq OWNED BY public.specializations.id_spec;


--
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    id_staff integer NOT NULL,
    fullname character varying(100) NOT NULL,
    birthdate date NOT NULL,
    phone character varying(15) NOT NULL,
    id_position integer NOT NULL,
    db_user character varying(32) NOT NULL,
    hiredate date DEFAULT CURRENT_DATE NOT NULL,
    firedate date,
    CONSTRAINT staff_check CHECK ((hiredate > birthdate)),
    CONSTRAINT staff_check1 CHECK (((firedate IS NULL) OR (firedate >= hiredate)))
);


ALTER TABLE public.staff OWNER TO postgres;

--
-- Name: staff_id_staff_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_id_staff_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_id_staff_seq OWNER TO postgres;

--
-- Name: staff_id_staff_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_id_staff_seq OWNED BY public.staff.id_staff;


--
-- Name: v_coachstats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_coachstats AS
 SELECT c.id_coach,
    s.fullname AS coachname,
    ( SELECT count(gci.id_instance) AS count
           FROM (public.groupscheduletemplates gst
             JOIN public.groupclassinstances gci ON ((gst.id_template = gci.id_template)))
          WHERE ((gst.id_coach = c.id_coach) AND (gci.classstatus = ANY (ARRAY['Completed'::public.activity_status, 'Attended'::public.activity_status])))) AS groupclassescount,
    ( SELECT round(COALESCE(avg(gci.actualattendance), (0)::numeric), 2) AS round
           FROM (public.groupscheduletemplates gst
             JOIN public.groupclassinstances gci ON ((gst.id_template = gci.id_template)))
          WHERE ((gst.id_coach = c.id_coach) AND (gci.classstatus = ANY (ARRAY['Completed'::public.activity_status, 'Attended'::public.activity_status])))) AS avggroupsize,
    ( SELECT count(DISTINCT sl.id_client) AS count
           FROM (public.personaltrainings pt
             JOIN public.sales sl ON ((pt.id_sale = sl.id_sale)))
          WHERE ((pt.id_coach = c.id_coach) AND (pt.trainingstatus = ANY (ARRAY['Completed'::public.activity_status, 'Attended'::public.activity_status])))) AS individualclientscount
   FROM (public.coaches c
     JOIN public.staff s ON ((c.id_staff = s.id_staff)));


ALTER VIEW public.v_coachstats OWNER TO postgres;

--
-- Name: v_groupindividualclientsshare; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_groupindividualclientsshare AS
 WITH groupclients AS (
         SELECT DISTINCT gst.id_template,
            ct.typename,
            gst.dayofweek,
            gst.starttime,
            sl.id_client
           FROM ((((public.groupscheduletemplates gst
             JOIN public.classtypes ct ON ((gst.id_classtype = ct.id_classtype)))
             JOIN public.groupclassinstances gci ON ((gst.id_template = gci.id_template)))
             JOIN public.groupclassbookings gcb ON ((gci.id_instance = gcb.id_instance)))
             JOIN public.sales sl ON ((gcb.id_sale = sl.id_sale)))
        ), personalclients AS (
         SELECT DISTINCT sl.id_client
           FROM (public.personaltrainings pt
             JOIN public.sales sl ON ((pt.id_sale = sl.id_sale)))
        )
 SELECT gc.id_template,
    gc.typename AS grouptype,
    gc.dayofweek,
    gc.starttime,
    count(gc.id_client) AS totalgroupclients,
    count(pc.id_client) AS clientswithpersonaltrainings,
        CASE
            WHEN (count(gc.id_client) = 0) THEN (0)::numeric
            ELSE round((((count(pc.id_client))::numeric / (count(gc.id_client))::numeric) * (100)::numeric), 2)
        END AS personaltrainingsharepercent
   FROM (groupclients gc
     LEFT JOIN personalclients pc ON ((gc.id_client = pc.id_client)))
  GROUP BY gc.id_template, gc.typename, gc.dayofweek, gc.starttime;


ALTER VIEW public.v_groupindividualclientsshare OWNER TO postgres;

--
-- Name: v_manager_id; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.v_manager_id (
    id_staff integer
);


ALTER TABLE public.v_manager_id OWNER TO postgres;

--
-- Name: visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visits (
    id_visit integer NOT NULL,
    id_hall integer NOT NULL,
    id_sale integer NOT NULL,
    checkintime timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.visits OWNER TO postgres;

--
-- Name: visits_id_visit_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visits_id_visit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visits_id_visit_seq OWNER TO postgres;

--
-- Name: visits_id_visit_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visits_id_visit_seq OWNED BY public.visits.id_visit;


--
-- Name: classtypes id_classtype; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classtypes ALTER COLUMN id_classtype SET DEFAULT nextval('public.classtypes_id_classtype_seq'::regclass);


--
-- Name: clients id_client; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients ALTER COLUMN id_client SET DEFAULT nextval('public.clients_id_client_seq'::regclass);


--
-- Name: clientsubscriptions id_clientsub; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientsubscriptions ALTER COLUMN id_clientsub SET DEFAULT nextval('public.clientsubscriptions_id_clientsub_seq'::regclass);


--
-- Name: coaches id_coach; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaches ALTER COLUMN id_coach SET DEFAULT nextval('public.coaches_id_coach_seq'::regclass);


--
-- Name: freezinglogs id_freezing; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freezinglogs ALTER COLUMN id_freezing SET DEFAULT nextval('public.freezinglogs_id_freezing_seq'::regclass);


--
-- Name: groupclassbookings id_booking; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassbookings ALTER COLUMN id_booking SET DEFAULT nextval('public.groupclassbookings_id_booking_seq'::regclass);


--
-- Name: groupclassinstances id_instance; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassinstances ALTER COLUMN id_instance SET DEFAULT nextval('public.groupclassinstances_id_instance_seq'::regclass);


--
-- Name: groupscheduletemplates id_template; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupscheduletemplates ALTER COLUMN id_template SET DEFAULT nextval('public.groupscheduletemplates_id_template_seq'::regclass);


--
-- Name: halls id_hall; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.halls ALTER COLUMN id_hall SET DEFAULT nextval('public.halls_id_hall_seq'::regclass);


--
-- Name: personaltrainings id_personal; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personaltrainings ALTER COLUMN id_personal SET DEFAULT nextval('public.personaltrainings_id_personal_seq'::regclass);


--
-- Name: positions id_position; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions ALTER COLUMN id_position SET DEFAULT nextval('public.positions_id_position_seq'::regclass);


--
-- Name: pricelist id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricelist ALTER COLUMN id_item SET DEFAULT nextval('public.pricelist_id_item_seq'::regclass);


--
-- Name: promocodes id_promo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promocodes ALTER COLUMN id_promo SET DEFAULT nextval('public.promocodes_id_promo_seq'::regclass);


--
-- Name: pt_changelog id_ptlog; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pt_changelog ALTER COLUMN id_ptlog SET DEFAULT nextval('public.pt_changelog_id_ptlog_seq'::regclass);


--
-- Name: sales id_sale; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales ALTER COLUMN id_sale SET DEFAULT nextval('public.sales_id_sale_seq'::regclass);


--
-- Name: specializations id_spec; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specializations ALTER COLUMN id_spec SET DEFAULT nextval('public.specializations_id_spec_seq'::regclass);


--
-- Name: staff id_staff; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff ALTER COLUMN id_staff SET DEFAULT nextval('public.staff_id_staff_seq'::regclass);


--
-- Name: visits id_visit; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits ALTER COLUMN id_visit SET DEFAULT nextval('public.visits_id_visit_seq'::regclass);


--
-- Data for Name: appliedpromo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appliedpromo (id_sale, id_promo) FROM stdin;
4	1
9	1
22	2
32	1
97	1
104	1
111	1
118	1
126	1
\.


--
-- Data for Name: classtypes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.classtypes (id_classtype, typename) FROM stdin;
1	Hatha Yoga
2	Power Crossfit
3	Zumba
4	Morning Stretch
5	Box Training
6	Aqua Aerobics
7	Pilates Basics
8	Body Pump
9	Total Abs
10	Tai Chi
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (id_client, fullname, birthdate, phone, gender, db_user) FROM stdin;
2	Клименко Ганна Миколаївна	2000-05-20	+380672222222	Female	client_hanna
3	Павленко Максим Андрійович	1995-11-30	+380673333333	Male	client_maksym
4	Дмитренко Ольга Володимирівна	1992-04-12	+380674444444	Female	client_olga
5	Савченко Ігор Олександрович	1988-08-25	+380675555555	Male	client_igor
6	Руденко Світлана Петрівна	1996-03-18	+380676666666	Female	client_svitlana
7	Кузьменко Денис Віталійович	1991-09-05	+380677777777	Male	client_denis
8	Жук Катерина Іванівна	1994-12-22	+380678888888	Female	client_kateryna
9	Поліщук Артем Дмитрович	1997-07-12	+380679999999	Male	client_artem
10	Білоус Наталія Юріївна	1993-01-05	+380670000000	Female	client_nataliya
23	Тестовий Клієнт Здоровий	1995-08-20	+380671286336	Female	user_vwv3sn
22	Іваненко Петро Сергійович	1991-03-25	+380508045242	Male	user_qmq351
27	Клієнт Без Абонемента	1999-01-01	+380932166928	Male	user_nosub_8c84t9
29	Тестовий Клієнт Здоровий	1995-08-20	+380674949012	Female	user_5bbf05
28	Іваненко Петро Сергійович	1991-03-25	+380503980145	Male	user_kzjnhu
33	Клієнт Без Абонемента	1999-01-01	+380934835840	Male	user_nosub_epm87x
35	Тестовий Клієнт Здоровий	1995-08-20	+380673803736	Female	user_fge9cn
34	Іваненко Петро Сергійович	1991-03-25	+380507895786	Male	user_e0n6y6
39	Клієнт Без Абонемента	1999-01-01	+380937326489	Male	user_nosub_hcdxhs
41	Тестовий Клієнт Здоровий	1995-08-20	+380672623839	Female	user_7wrgm0
40	Іваненко Петро Сергійович	1991-03-25	+380509047060	Male	user_rt9buu
45	Клієнт Без Абонемента	1999-01-01	+380938602416	Male	user_nosub_by6vax
47	Тестовий Клієнт Здоровий	1995-08-20	+380673410517	Female	user_pdpbhq
46	Іваненко Петро Сергійович	1991-03-25	+380501904492	Male	user_gy1jjl
1	Остапенко Віталій Сергійович	1998-02-14	+380671111111	Male	user_oleksandr
51	Клієнт Без Абонемента	1999-01-01	+380936632320	Male	user_nosub_xfynqd
\.


--
-- Data for Name: clientsubscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientsubscriptions (id_clientsub, id_sale, startdate, enddate, currentstatus, remainingfreezingdays) FROM stdin;
2	2	2026-01-10	2026-07-10	Active	23
3	3	2026-01-01	2027-01-01	Active	50
4	4	2026-04-15	2026-05-15	Expired	0
5	5	2026-05-10	2026-06-09	Frozen	0
6	6	2026-05-20	2026-06-19	Active	7
13	96	2026-10-14	2026-11-13	Active	7
14	97	2026-10-14	2026-11-13	Active	7
15	98	2026-10-14	2026-11-13	Active	7
16	103	2026-10-14	2026-11-13	Active	7
17	104	2026-10-14	2026-11-13	Active	7
18	105	2026-10-14	2026-11-13	Active	7
1	1	2026-05-01	2026-06-06	Frozen	1
19	110	2026-10-14	2026-11-13	Active	7
20	111	2026-10-14	2026-11-13	Active	7
21	112	2026-10-14	2026-11-13	Active	7
22	117	2026-10-14	2026-11-13	Active	7
23	118	2026-10-14	2026-11-13	Active	7
24	119	2026-10-14	2026-11-13	Active	7
26	125	2026-10-14	2026-11-13	Active	7
27	126	2026-10-14	2026-11-13	Active	7
28	127	2026-10-14	2026-11-13	Active	7
25	124	2026-10-15	2026-11-16	Frozen	5
29	132	2026-10-15	2026-11-14	Active	7
30	133	2026-10-15	2026-11-14	Active	7
31	134	2026-10-14	2026-11-13	Active	7
\.


--
-- Data for Name: coaches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.coaches (id_coach, id_staff, id_spec, biography) FROM stdin;
2	5	2	Сертифікований інструктор з Хатха-йоги. Проходила навчання в Індії.
3	6	4	Багаторазовий призер регіональних змагань з Crossfit.
4	7	7	Професійна артистка балету в минулому. Експерт зі стретчингу.
5	8	5	Кандидат у майстри спорту з боксу. Має глибокі знання техніки ударів.
6	9	1	Спеціаліст з функціонального тренінгу та корекції постави.
7	10	3	Дипломований реабілітолог та інструктор з пілатесу.
15	22	4	Оновлена біографія: сертифікований тренер CrossFit Level 2
16	24	4	Оновлена біографія: сертифікований тренер CrossFit Level 2
17	26	4	Оновлена біографія: сертифікований тренер CrossFit Level 2
18	28	4	Оновлена біографія: сертифікований тренер CrossFit Level 2
19	30	4	Оновлена біографія: сертифікований тренер CrossFit Level 2
20	32	4	Оновлена біографія: сертифікований тренер CrossFit Level 2
1	4	1	Майстер спорту. Учасник олімпіади 2024 та зайняв 4-е місце серед 32 учасників.
\.


--
-- Data for Name: freezinglogs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.freezinglogs (id_freezing, id_clientsub, freezestartdate, freezeenddate, reason) FROM stdin;
1	2	2026-03-01	2026-03-08	Відпустка
2	3	2026-02-10	2026-02-20	Хвороба (ГРВІ)
3	5	2026-05-24	2026-05-31	Відрядження
4	2	2026-03-01	2026-03-08	Відпустка
5	3	2026-02-10	2026-02-20	Хвороба (ГРВІ)
6	5	2026-05-24	2026-05-31	Відрядження
7	1	2026-10-15	2026-10-17	Відпустка по роботі
8	1	2026-10-15	2026-10-17	Відпустка по роботі
9	1	2026-10-15	2026-10-17	Відпустка по роботі
10	25	2026-10-15	2026-10-17	Відпустка по роботі
\.


--
-- Data for Name: groupclassbookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groupclassbookings (id_booking, id_instance, id_sale, bookingstatus) FROM stdin;
1	1	20	Attended
2	2	21	Attended
3	3	22	Attended
4	4	23	Attended
5	5	24	Scheduled
6	6	25	Scheduled
7	1	26	Attended
8	1	27	Cancelled
9	2	28	Cancelled
10	3	29	Cancelled
11	1	32	No-show
12	2	33	No-show
13	3	34	No-show
14	3	35	Attended
15	5	36	Scheduled
16	6	37	Scheduled
17	1	38	Attended
18	4	39	Attended
19	5	40	Scheduled
20	7	41	Cancelled
41	1	99	Scheduled
42	1	106	Scheduled
43	1	113	Scheduled
44	1	120	Scheduled
45	1	128	Scheduled
46	1	136	Scheduled
\.


--
-- Data for Name: groupclassinstances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groupclassinstances (id_instance, id_template, classdate, classstatus, actualattendance, classstarttime) FROM stdin;
2	2	2026-05-19	Scheduled	1	18:00:00
3	3	2026-05-20	Scheduled	2	08:00:00
4	4	2026-05-25	Scheduled	2	19:00:00
5	5	2026-05-27	Scheduled	0	17:00:00
6	6	2026-05-28	Scheduled	0	11:00:00
7	1	2026-05-25	Cancelled	0	10:00:00
8	1	2026-05-18	Completed	3	09:00:00
9	2	2026-05-19	Completed	1	18:00:00
10	3	2026-05-20	Completed	2	08:00:00
11	4	2026-05-25	Completed	2	19:00:00
12	5	2026-05-27	Scheduled	0	17:00:00
13	6	2026-05-28	Scheduled	0	11:00:00
14	1	2026-05-25	Cancelled	0	10:00:00
15	13	2026-05-28	Completed	12	18:00:00
1	1	2026-05-18	Scheduled	9	09:00:00
\.


--
-- Data for Name: groupscheduletemplates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groupscheduletemplates (id_template, id_classtype, dayofweek, starttime, durationminutes, id_hall, id_coach) FROM stdin;
1	1	1	09:00:00	60	2	2
2	2	2	18:00:00	90	4	3
3	4	3	08:00:00	45	2	4
4	3	4	19:00:00	60	3	5
5	5	5	17:00:00	60	1	6
6	7	6	11:00:00	60	6	7
7	1	1	09:00:00	60	2	2
8	2	2	18:00:00	90	4	3
9	4	3	08:00:00	45	2	4
10	3	4	19:00:00	60	3	5
11	5	5	17:00:00	60	1	6
12	7	6	11:00:00	60	6	7
13	2	4	18:00:00	60	4	1
14	1	3	14:00:00	60	4	3
\.


--
-- Data for Name: halls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.halls (id_hall, hallname, maxcapacity, isactive) FROM stdin;
1	Main Gym	50	t
2	Yoga Studio	15	t
3	Fight Zone	20	t
4	Crossfit Box	25	t
5	Pool	30	t
6	Pilates Room	10	t
7	Kids Zone	15	t
9	QA_Test_Hall_mve91zhi	45	f
8	QA_Test_Hall_mve8wkg6	45	f
\.


--
-- Data for Name: medicalnotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicalnotes (id_client, notestext) FROM stdin;
2	Грижа в поперековому відділі хребта. Заборонені осьові навантаження та стрибки.
4	Астма. Потребує постійного доступу до інгалятора під час тренувань.
6	Травма коліна (меніск). Рекомендовано уникати глибоких присідань та великих ваг.
8	Гіпертонія 1 ступеня. Потрібно контролювати пульс та уникати тривалих нахилів головою вниз.
10	Вагітність. Спеціалізована програма, виключення вправ на м'язи преса.
22	Реабілітація після перелому
28	Реабілітація після перелому
34	Реабілітація після перелому
40	Реабілітація після перелому
46	Реабілітація після перелому
1	Здоровий, без обмежень
51	Гіпертонія 2 ст., заборонено важкі навантаження
\.


--
-- Data for Name: personaltrainings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personaltrainings (id_personal, id_coach, id_hall, id_sale, trainingdatetime, trainingstatus) FROM stdin;
1	1	1	7	2026-05-12 10:00:00	Completed
2	3	4	8	2026-05-14 18:30:00	Completed
3	1	1	9	2026-05-18 11:00:00	Completed
4	2	2	10	2026-05-20 12:00:00	Completed
5	4	4	11	2026-05-26 10:00:00	Completed
6	5	1	12	2026-05-27 10:00:00	Scheduled
7	6	4	13	2026-05-27 19:00:00	Scheduled
8	1	1	14	2026-05-28 11:00:00	Scheduled
9	2	2	15	2026-05-28 14:00:00	Scheduled
10	3	4	16	2026-05-29 16:00:00	Scheduled
11	1	1	17	2026-05-25 10:00:00	Cancelled
12	2	2	18	2026-05-26 09:00:00	Cancelled
13	3	4	19	2026-05-30 18:00:00	Scheduled
14	1	1	42	2026-05-27 17:00:00	Scheduled
15	1	1	43	2026-05-11 10:00:00	Completed
16	2	1	44	2026-05-11 10:00:00	Completed
17	3	1	45	2026-05-11 10:00:00	Completed
18	4	1	46	2026-05-11 10:00:00	Completed
19	5	1	47	2026-05-11 10:00:00	Completed
20	6	1	48	2026-05-11 10:00:00	Completed
21	7	1	49	2026-05-11 10:00:00	Completed
36	1	1	101	2026-10-19 11:00:00	Cancelled
37	2	2	102	2026-10-22 13:00:00	Scheduled
38	1	1	108	2026-10-19 11:00:00	Cancelled
39	2	2	109	2026-10-21 09:00:00	Scheduled
40	1	1	115	2026-10-19 11:00:00	Cancelled
41	2	2	116	2026-11-03 13:00:00	Scheduled
42	1	1	122	2026-10-19 11:00:00	Cancelled
43	2	2	123	2026-11-10 13:00:00	Scheduled
44	1	1	130	2026-10-19 11:00:00	Cancelled
45	2	2	131	2026-12-05 13:00:00	Scheduled
35	1	1	91	2026-05-27 17:00:00	Completed
46	1	1	135	2026-10-25 15:00:00	Scheduled
53	1	1	139	2026-05-12 10:00:00	Completed
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.positions (id_position, positionname) FROM stdin;
2	Старший тренер
3	Тренер
5	Директор
4	HR Менеджер
1	Менеджер клієнтів
11	Адміністратор
\.


--
-- Data for Name: pricelist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pricelist (id_item, itemname, category, price, pricestartdate, description) FROM stdin;
1	Базовий абонемент (1 місяць)	Membership	1200.00	2026-05-26	Доступ до тренажерного залу на 30 днів.
2	Піврічний абонемент (Стандарт)	Membership	6000.00	2026-05-26	6 місяців занять.
3	Річний безліміт (Gold)	Membership	10000.00	2026-05-26	12 місяців занять.
4	Персональне тренування з експертом	Personal training	400.00	2026-05-26	Індивідуальне заняття 60 хв.
5	Разове групове заняття	Group training	200.00	2026-05-26	Одне групове заняття.
6	Дитяче тренування (Kids Fitness)	Group training	150.00	2026-05-26	Заняття для дітей.
\.


--
-- Data for Name: pricelistsubs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pricelistsubs (id_item, durationdays, maxfreezingdays) FROM stdin;
1	30	7
2	180	30
3	365	60
\.


--
-- Data for Name: promocodes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.promocodes (id_promo, codetext, discountpercent, expirydate) FROM stdin;
1	OPEN10	10	2026-12-31
2	SALE30	30	2026-06-01
\.


--
-- Data for Name: pt_changelog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pt_changelog (id_ptlog, id_personal, requesttype, reason, changeinitiator, changetimestamp) FROM stdin;
1	11	Cancel	Хворобта	Client	2026-05-24 18:00:00
2	12	Cancel	Термінова нарада	Client	2026-05-26 08:15:00
3	4	Reschedule	Участь у семінарі	Coach	2026-05-19 14:00:00
4	11	Cancel	Хвороба	Client	2026-05-24 18:00:00
5	12	Cancel	Термінова нарада	Client	2026-05-26 08:15:00
6	4	Reschedule	Участь у семінарі	Coach	2026-05-19 14:00:00
8	36	Cancel	Клієнт захворів на грип	Manager	2026-10-14 20:42:37.458696
9	37	Reschedule	За проханням тренера	Manager	2026-10-14 20:42:37.52429
10	38	Cancel	Клієнт захворів на грип	Manager	2026-10-14 20:54:02.920062
11	40	Cancel	Клієнт захворів на грип	Manager	2026-10-14 21:39:20.876905
12	41	Reschedule	За проханням тренера	Manager	2026-10-14 21:39:20.942966
13	42	Cancel	Клієнт захворів на грип	Manager	2026-10-14 21:42:09.66173
14	43	Reschedule	За проханням тренера	Manager	2026-10-14 21:42:09.72725
15	44	Cancel	Клієнт захворів на грип	Manager	2026-10-14 21:50:04.629698
16	45	Reschedule	За проханням тренера	Manager	2026-10-14 21:50:04.694871
17	14	Reschedule	Тестове перенесення від тренера QA	Coach	2026-10-14 22:02:18.599697
\.


--
-- Data for Name: pt_timechangedetails; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pt_timechangedetails (id_ptlog, olddatetime, newdatetime) FROM stdin;
3	2026-05-20 10:00:00	2026-05-20 12:00:00
9	2026-10-21 09:00:00	2026-10-22 13:00:00
12	2026-11-02 07:00:00	2026-11-03 13:00:00
14	2026-11-09 07:00:00	2026-11-10 13:00:00
16	2026-12-04 07:00:00	2026-12-05 13:00:00
17	2026-05-27 17:00:00	2026-11-20 15:00:00
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sales (id_sale, id_client, id_item, saledate, id_manager, saleprice) FROM stdin;
1	1	1	2026-05-01 10:00:00	2	1200.00
2	2	2	2026-01-10 12:00:00	2	6000.00
3	3	3	2026-01-01 09:00:00	2	10000.00
4	4	1	2026-04-15 11:00:00	2	1080.00
5	7	1	2026-05-10 15:00:00	2	1200.00
6	10	1	2026-05-20 18:00:00	2	1200.00
7	5	4	2026-05-10 10:00:00	3	400.00
8	9	4	2026-05-12 11:00:00	3	400.00
9	1	4	2026-05-15 09:00:00	2	360.00
10	2	4	2026-05-18 14:00:00	3	400.00
11	5	4	2026-05-26 10:00:00	3	400.00
12	6	4	2026-05-26 14:00:00	3	400.00
13	7	4	2026-05-27 10:00:00	3	400.00
14	2	4	2026-05-27 11:00:00	3	400.00
15	9	4	2026-05-28 12:00:00	3	400.00
16	10	4	2026-05-28 13:00:00	3	400.00
17	1	4	2026-05-29 09:00:00	3	400.00
18	2	4	2026-05-29 10:00:00	3	400.00
19	3	4	2026-05-29 11:00:00	3	400.00
20	6	5	2026-05-20 10:00:00	3	200.00
21	3	5	2026-05-21 11:00:00	3	200.00
22	4	5	2026-05-22 12:00:00	2	140.00
23	1	5	2026-05-23 09:00:00	3	200.00
24	2	5	2026-05-24 14:00:00	3	200.00
25	3	5	2026-05-24 15:00:00	3	200.00
26	4	5	2026-05-25 10:00:00	3	200.00
27	7	5	2026-05-26 11:00:00	3	200.00
28	8	5	2026-05-26 12:00:00	3	200.00
29	9	5	2026-05-27 13:00:00	3	200.00
30	10	5	2026-05-27 14:00:00	3	200.00
31	1	5	2026-05-27 15:00:00	3	200.00
32	8	6	2026-05-20 10:00:00	3	150.00
33	9	6	2026-05-21 11:00:00	3	150.00
34	10	6	2026-05-22 12:00:00	3	150.00
35	5	6	2026-05-23 13:00:00	3	150.00
36	6	6	2026-05-24 14:00:00	3	150.00
37	4	6	2026-05-25 15:00:00	3	150.00
38	5	6	2026-05-26 09:00:00	3	150.00
39	1	6	2026-05-26 10:00:00	3	150.00
40	2	6	2026-05-26 11:00:00	3	150.00
41	3	6	2026-05-26 12:00:00	3	150.00
42	1	4	2026-05-26 15:00:00	3	400.00
43	7	4	2026-05-10 10:00:00	3	400.00
44	7	4	2026-05-10 10:00:00	3	400.00
45	7	4	2026-05-10 10:00:00	3	400.00
46	7	4	2026-05-10 10:00:00	3	400.00
47	7	4	2026-05-10 10:00:00	3	400.00
48	7	4	2026-05-10 10:00:00	3	400.00
49	7	4	2026-05-10 10:00:00	3	400.00
50	1	1	2026-05-01 10:00:00	2	1200.00
51	2	2	2026-01-10 12:00:00	2	6000.00
52	3	3	2026-01-01 09:00:00	2	10000.00
53	4	1	2026-04-15 11:00:00	2	1080.00
54	7	1	2026-05-10 15:00:00	2	1200.00
55	10	1	2026-05-20 18:00:00	2	1200.00
56	5	4	2026-05-10 10:00:00	3	400.00
57	9	4	2026-05-12 11:00:00	3	400.00
58	1	4	2026-05-15 09:00:00	2	360.00
59	2	4	2026-05-18 14:00:00	3	400.00
60	5	4	2026-05-26 10:00:00	3	400.00
61	6	4	2026-05-26 14:00:00	3	400.00
62	7	4	2026-05-27 10:00:00	3	400.00
63	2	4	2026-05-27 11:00:00	3	400.00
64	9	4	2026-05-28 12:00:00	3	400.00
65	10	4	2026-05-28 13:00:00	3	400.00
66	1	4	2026-05-29 09:00:00	3	400.00
67	2	4	2026-05-29 10:00:00	3	400.00
68	3	4	2026-05-29 11:00:00	3	400.00
69	6	5	2026-05-20 10:00:00	3	200.00
70	3	5	2026-05-21 11:00:00	3	200.00
71	4	5	2026-05-22 12:00:00	2	140.00
72	1	5	2026-05-23 09:00:00	3	200.00
73	2	5	2026-05-24 14:00:00	3	200.00
74	3	5	2026-05-24 15:00:00	3	200.00
75	4	5	2026-05-25 10:00:00	3	200.00
76	7	5	2026-05-26 11:00:00	3	200.00
77	8	5	2026-05-26 12:00:00	3	200.00
78	9	5	2026-05-27 13:00:00	3	200.00
79	10	5	2026-05-27 14:00:00	3	200.00
80	1	5	2026-05-27 15:00:00	3	200.00
81	8	6	2026-05-20 10:00:00	3	150.00
82	9	6	2026-05-21 11:00:00	3	150.00
83	10	6	2026-05-22 12:00:00	3	150.00
84	5	6	2026-05-23 13:00:00	3	150.00
85	6	6	2026-05-24 14:00:00	3	150.00
86	4	6	2026-05-25 15:00:00	3	150.00
87	5	6	2026-05-26 09:00:00	3	150.00
88	1	6	2026-05-26 10:00:00	3	150.00
89	2	6	2026-05-26 11:00:00	3	150.00
90	3	6	2026-05-26 12:00:00	3	150.00
91	1	4	2026-05-26 15:00:00	3	400.00
96	22	1	2026-10-14 20:42:36.966666	2	1200.00
97	23	1	2026-10-14 20:42:37.006842	2	1080.00
98	23	1	2026-10-14 20:42:37.058877	2	1200.00
99	22	5	2026-10-14 20:42:37.188977	1	200.00
101	22	4	2026-10-14 20:42:37.275542	1	400.00
102	22	4	2026-10-14 20:42:37.479374	1	400.00
103	28	1	2026-10-14 20:54:02.419127	2	1200.00
104	29	1	2026-10-14 20:54:02.462372	2	1080.00
105	29	1	2026-10-14 20:54:02.514567	2	1200.00
106	28	5	2026-10-14 20:54:02.649524	1	200.00
108	28	4	2026-10-14 20:54:02.739543	1	400.00
109	28	4	2026-10-14 20:54:02.941044	1	400.00
110	34	1	2026-10-14 21:39:20.43695	2	1200.00
111	35	1	2026-10-14 21:39:20.481287	2	1080.00
112	35	1	2026-10-14 21:39:20.524065	2	1200.00
113	34	5	2026-10-14 21:39:20.654681	1	200.00
115	34	4	2026-10-14 21:39:20.745221	1	400.00
116	34	4	2026-10-14 21:39:20.896465	1	400.00
117	40	1	2026-10-14 21:42:09.295182	2	1200.00
118	41	1	2026-10-14 21:42:09.32423	2	1080.00
119	41	1	2026-10-14 21:42:09.36875	2	1200.00
120	40	5	2026-10-14 21:42:09.490148	1	200.00
122	40	4	2026-10-14 21:42:09.563439	1	400.00
123	40	4	2026-10-14 21:42:09.680232	1	400.00
124	1	1	2026-10-14 21:49:49.163247	2	1200.00
125	46	1	2026-10-14 21:50:04.12266	2	1200.00
126	47	1	2026-10-14 21:50:04.170445	2	1080.00
127	47	1	2026-10-14 21:50:04.218583	2	1200.00
128	46	5	2026-10-14 21:50:04.347198	2	200.00
130	46	4	2026-10-14 21:50:04.433994	2	400.00
131	46	4	2026-10-14 21:50:04.650411	2	400.00
132	1	1	2026-10-14 21:50:19.540031	2	1200.00
133	1	1	2026-10-14 21:50:20.485199	2	1200.00
134	51	1	2026-10-14 22:00:34.837096	2	1200.00
135	51	4	2026-10-14 22:03:48.667163	2	400.00
136	51	5	2026-10-14 22:04:31.423082	2	200.00
139	5	4	2026-05-10 10:00:00	3	400.00
144	1	4	2026-10-19 16:40:38.820113	2	400.00
\.


--
-- Data for Name: specializations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specializations (id_spec, specname) FROM stdin;
1	Тренажерний зал
2	Йога
3	Пілатес
4	Кроссфіт
5	Бокс
6	Плавання
7	Стретчинг
8	Дитячий фітнес
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff (id_staff, fullname, birthdate, phone, id_position, db_user, hiredate, firedate) FROM stdin;
1	Іваненко Іван Іванович	1985-05-15	+380501111111	5	boss_ivan	2020-01-01	\N
2	Петренко Петро Петрович	1990-08-20	+380502222222	1	manager_petro	2021-03-10	\N
3	Сидоренко Олена Сергіївна	1992-12-05	+380503333333	4	admin_olena	2022-05-15	\N
5	Бондаренко Марія Олександрівна	1995-07-12	+380505555555	3	coach_mariya	2023-02-01	\N
6	Мельник Дмитро Ігорович	1991-11-30	+380506666666	3	coach_dima	2022-09-15	\N
7	Шевченко Юлія Володимирівна	1994-04-18	+380507777777	3	coach_yulia	2023-05-10	\N
8	Ткаченко Сергій Михайлович	1987-09-05	+380508888888	3	coach_serg	2021-11-20	\N
9	Кузнецов Олег Петрович	1993-06-10	+380509999901	3	coach_oleg	2023-01-10	\N
10	Лебедєва Анна Сергіївна	1995-09-22	+380509999902	3	coach_anna	2023-05-15	\N
21	Тест Менеджер	1990-01-01	+380509058405	1	mgr_t_3lkqc	2026-10-14	2026-10-14
22	Бондаренко Олексій Валерійович (PRO)	1988-04-12	+380976258022	2	coach_k3v0kc	2026-10-14	2026-10-14
23	Шевченко Марія Вікторівна (Старший)	1993-09-18	+380665125255	1	mgr_qb63kp	2026-10-14	2026-10-14
24	Бондаренко Олексій Валерійович (PRO)	1988-04-12	+380979073873	2	coach_ipulgx	2026-10-14	2026-10-14
25	Шевченко Марія Вікторівна (Старший)	1993-09-18	+380666395883	1	mgr_9jbqnk	2026-10-14	2026-10-14
26	Бондаренко Олексій Валерійович (PRO)	1988-04-12	+380976055142	2	coach_0jee4h	2026-10-14	2026-10-14
27	Шевченко Марія Вікторівна (Старший)	1993-09-18	+380665315573	1	mgr_jeuk6f	2026-10-14	2026-10-14
28	Бондаренко Олексій Валерійович (PRO)	1988-04-12	+380971278244	2	coach_92y0ld	2026-10-14	2026-10-14
29	Шевченко Марія Вікторівна (Старший)	1993-09-18	+380661048008	1	mgr_lxkote	2026-10-14	2026-10-14
30	Бондаренко Олексій Валерійович (PRO)	1988-04-12	+380978078470	2	coach_6ukuuu	2026-10-14	2026-10-14
31	Шевченко Марія Вікторівна (Старший)	1993-09-18	+380666443993	1	mgr_pexfhz	2026-10-14	2026-10-14
32	Бондаренко Олексій Валерійович (PRO)	1988-04-12	+380978762910	2	coach_ftw1uc	2026-10-14	2026-10-14
33	Шевченко Марія Вікторівна (Старший)	1993-09-18	+380665283227	4	mgr_8kepol	2026-10-14	2026-10-14
34	Тестовий Менеджер 4050	1990-01-01	+3805040504050	1	usr_mgr_4050	2026-10-14	2026-10-14
4	Коваленко Андрій Вікторович	1988-03-25	+380504444444	2	coach_maksym	2021-01-20	\N
\.


--
-- Data for Name: v_manager_id; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.v_manager_id (id_staff) FROM stdin;
2
\.


--
-- Data for Name: visits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visits (id_visit, id_hall, id_sale, checkintime) FROM stdin;
1	1	1	2026-05-02 09:15:00
2	1	1	2026-05-04 10:00:00
3	1	3	2026-05-20 17:30:00
4	1	5	2026-05-12 12:00:00
5	1	6	2026-05-25 18:00:00
6	4	3	2026-05-26 10:00:00
7	2	4	2026-05-05 09:00:00
8	1	1	2026-05-02 09:15:00
9	1	1	2026-05-04 10:00:00
10	1	3	2026-05-20 17:30:00
11	1	5	2026-05-12 12:00:00
12	1	6	2026-05-25 18:00:00
13	4	3	2026-05-26 10:00:00
14	2	4	2026-05-05 09:00:00
15	1	96	2026-10-14 20:42:37.093577
16	1	103	2026-10-14 20:54:02.547983
17	1	110	2026-10-14 21:39:20.559333
18	1	117	2026-10-14 21:42:09.400192
19	1	125	2026-10-14 21:50:04.251738
20	1	134	2026-10-14 22:02:46.524344
21	1	125	2026-10-16 17:56:41.732892
22	1	117	2026-10-16 18:26:00.954137
23	1	132	2026-10-18 22:59:58.467474
24	1	118	2026-10-19 16:42:07.98943
\.


--
-- Name: classtypes_id_classtype_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.classtypes_id_classtype_seq', 20, true);


--
-- Name: clients_id_client_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clients_id_client_seq', 51, true);


--
-- Name: clientsubscriptions_id_clientsub_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientsubscriptions_id_clientsub_seq', 31, true);


--
-- Name: coaches_id_coach_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.coaches_id_coach_seq', 20, true);


--
-- Name: freezinglogs_id_freezing_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.freezinglogs_id_freezing_seq', 10, true);


--
-- Name: groupclassbookings_id_booking_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.groupclassbookings_id_booking_seq', 46, true);


--
-- Name: groupclassinstances_id_instance_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.groupclassinstances_id_instance_seq', 18, true);


--
-- Name: groupscheduletemplates_id_template_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.groupscheduletemplates_id_template_seq', 14, true);


--
-- Name: halls_id_hall_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.halls_id_hall_seq', 9, true);


--
-- Name: personaltrainings_id_personal_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personaltrainings_id_personal_seq', 60, true);


--
-- Name: positions_id_position_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.positions_id_position_seq', 11, true);


--
-- Name: pricelist_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pricelist_id_item_seq', 6, true);


--
-- Name: promocodes_id_promo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.promocodes_id_promo_seq', 4, true);


--
-- Name: pt_changelog_id_ptlog_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pt_changelog_id_ptlog_seq', 17, true);


--
-- Name: sales_id_sale_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sales_id_sale_seq', 144, true);


--
-- Name: specializations_id_spec_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.specializations_id_spec_seq', 16, true);


--
-- Name: staff_id_staff_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.staff_id_staff_seq', 34, true);


--
-- Name: visits_id_visit_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visits_id_visit_seq', 24, true);


--
-- Name: appliedpromo appliedpromo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appliedpromo
    ADD CONSTRAINT appliedpromo_pkey PRIMARY KEY (id_sale);


--
-- Name: classtypes classtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classtypes
    ADD CONSTRAINT classtypes_pkey PRIMARY KEY (id_classtype);


--
-- Name: classtypes classtypes_typename_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classtypes
    ADD CONSTRAINT classtypes_typename_key UNIQUE (typename);


--
-- Name: clients clients_db_user_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_db_user_key UNIQUE (db_user);


--
-- Name: clients clients_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_phone_key UNIQUE (phone);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id_client);


--
-- Name: clientsubscriptions clientsubscriptions_id_sale_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientsubscriptions
    ADD CONSTRAINT clientsubscriptions_id_sale_key UNIQUE (id_sale);


--
-- Name: clientsubscriptions clientsubscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientsubscriptions
    ADD CONSTRAINT clientsubscriptions_pkey PRIMARY KEY (id_clientsub);


--
-- Name: coaches coaches_id_staff_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaches
    ADD CONSTRAINT coaches_id_staff_key UNIQUE (id_staff);


--
-- Name: coaches coaches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaches
    ADD CONSTRAINT coaches_pkey PRIMARY KEY (id_coach);


--
-- Name: freezinglogs freezinglogs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freezinglogs
    ADD CONSTRAINT freezinglogs_pkey PRIMARY KEY (id_freezing);


--
-- Name: uq_group_booking_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_group_booking_active ON public.groupclassbookings USING btree (id_instance, id_sale) WHERE (bookingstatus = 'Scheduled'::public.activity_status);


--
-- Name: groupclassbookings groupclassbookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassbookings
    ADD CONSTRAINT groupclassbookings_pkey PRIMARY KEY (id_booking);


--
-- Name: groupclassinstances groupclassinstances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassinstances
    ADD CONSTRAINT groupclassinstances_pkey PRIMARY KEY (id_instance);


--
-- Name: groupscheduletemplates groupscheduletemplates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupscheduletemplates
    ADD CONSTRAINT groupscheduletemplates_pkey PRIMARY KEY (id_template);


--
-- Name: halls halls_hallname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_hallname_key UNIQUE (hallname);


--
-- Name: halls halls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.halls
    ADD CONSTRAINT halls_pkey PRIMARY KEY (id_hall);


--
-- Name: medicalnotes medicalnotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicalnotes
    ADD CONSTRAINT medicalnotes_pkey PRIMARY KEY (id_client);


--
-- Name: personaltrainings personaltrainings_id_sale_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personaltrainings
    ADD CONSTRAINT personaltrainings_id_sale_key UNIQUE (id_sale);


--
-- Name: personaltrainings personaltrainings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personaltrainings
    ADD CONSTRAINT personaltrainings_pkey PRIMARY KEY (id_personal);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id_position);


--
-- Name: positions positions_positionname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_positionname_key UNIQUE (positionname);


--
-- Name: pricelist pricelist_itemname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricelist
    ADD CONSTRAINT pricelist_itemname_key UNIQUE (itemname);


--
-- Name: pricelist pricelist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricelist
    ADD CONSTRAINT pricelist_pkey PRIMARY KEY (id_item);


--
-- Name: pricelistsubs pricelistsubs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricelistsubs
    ADD CONSTRAINT pricelistsubs_pkey PRIMARY KEY (id_item);


--
-- Name: promocodes promocodes_codetext_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promocodes
    ADD CONSTRAINT promocodes_codetext_key UNIQUE (codetext);


--
-- Name: promocodes promocodes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promocodes
    ADD CONSTRAINT promocodes_pkey PRIMARY KEY (id_promo);


--
-- Name: pt_changelog pt_changelog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pt_changelog
    ADD CONSTRAINT pt_changelog_pkey PRIMARY KEY (id_ptlog);


--
-- Name: pt_timechangedetails pt_timechangedetails_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pt_timechangedetails
    ADD CONSTRAINT pt_timechangedetails_pkey PRIMARY KEY (id_ptlog);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id_sale);


--
-- Name: specializations specializations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_pkey PRIMARY KEY (id_spec);


--
-- Name: specializations specializations_specname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_specname_key UNIQUE (specname);


--
-- Name: staff staff_db_user_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_db_user_key UNIQUE (db_user);


--
-- Name: staff staff_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_phone_key UNIQUE (phone);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id_staff);


--
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id_visit);


--
-- Name: idx_clients_dbuser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_dbuser ON public.clients USING btree (db_user);


--
-- Name: idx_clients_fullname; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_fullname ON public.clients USING btree (fullname);


--
-- Name: idx_clients_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_phone ON public.clients USING btree (phone);


--
-- Name: idx_group_instances_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_instances_date ON public.groupclassinstances USING btree (classdate);


--
-- Name: idx_group_instances_template; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_instances_template ON public.groupclassinstances USING btree (id_template);


--
-- Name: idx_personal_trainings_coach; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_personal_trainings_coach ON public.personaltrainings USING btree (id_coach);


--
-- Name: idx_personal_trainings_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_personal_trainings_time ON public.personaltrainings USING btree (trainingdatetime);


--
-- Name: idx_sales_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sales_client ON public.sales USING btree (id_client);


--
-- Name: idx_sales_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sales_date ON public.sales USING btree (saledate);


--
-- Name: idx_staff_dbuser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_dbuser ON public.staff USING btree (db_user);


--
-- Name: idx_staff_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_phone ON public.staff USING btree (phone);


--
-- Name: idx_visits_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_visits_time ON public.visits USING btree (checkintime);


--
-- Name: uq_coach_active_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_coach_active_slot ON public.personaltrainings USING btree (id_coach, trainingdatetime) WHERE (trainingstatus = 'Scheduled'::public.activity_status);


--
-- Name: groupclassinstances trg_check_group_class_coach_conflict; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_group_class_coach_conflict BEFORE INSERT OR UPDATE OF id_template, classdate, classstarttime, classstatus ON public.groupclassinstances FOR EACH ROW EXECUTE FUNCTION public.check_coach_schedule_conflict();


--
-- Name: personaltrainings trg_check_personal_training_coach_conflict; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_personal_training_coach_conflict BEFORE INSERT OR UPDATE OF id_coach, trainingdatetime, trainingstatus ON public.personaltrainings FOR EACH ROW EXECUTE FUNCTION public.check_coach_schedule_conflict();


--
-- Name: appliedpromo appliedpromo_id_promo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appliedpromo
    ADD CONSTRAINT appliedpromo_id_promo_fkey FOREIGN KEY (id_promo) REFERENCES public.promocodes(id_promo);


--
-- Name: appliedpromo appliedpromo_id_sale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appliedpromo
    ADD CONSTRAINT appliedpromo_id_sale_fkey FOREIGN KEY (id_sale) REFERENCES public.sales(id_sale) ON DELETE CASCADE;


--
-- Name: clientsubscriptions clientsubscriptions_id_sale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientsubscriptions
    ADD CONSTRAINT clientsubscriptions_id_sale_fkey FOREIGN KEY (id_sale) REFERENCES public.sales(id_sale) ON DELETE CASCADE;


--
-- Name: coaches coaches_id_spec_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaches
    ADD CONSTRAINT coaches_id_spec_fkey FOREIGN KEY (id_spec) REFERENCES public.specializations(id_spec);


--
-- Name: coaches coaches_id_staff_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaches
    ADD CONSTRAINT coaches_id_staff_fkey FOREIGN KEY (id_staff) REFERENCES public.staff(id_staff) ON DELETE CASCADE;


--
-- Name: freezinglogs freezinglogs_id_clientsub_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freezinglogs
    ADD CONSTRAINT freezinglogs_id_clientsub_fkey FOREIGN KEY (id_clientsub) REFERENCES public.clientsubscriptions(id_clientsub) ON DELETE CASCADE;


--
-- Name: groupclassbookings groupclassbookings_id_instance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassbookings
    ADD CONSTRAINT groupclassbookings_id_instance_fkey FOREIGN KEY (id_instance) REFERENCES public.groupclassinstances(id_instance) ON DELETE CASCADE;


--
-- Name: groupclassbookings groupclassbookings_id_sale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassbookings
    ADD CONSTRAINT groupclassbookings_id_sale_fkey FOREIGN KEY (id_sale) REFERENCES public.sales(id_sale);


--
-- Name: groupclassinstances groupclassinstances_id_template_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupclassinstances
    ADD CONSTRAINT groupclassinstances_id_template_fkey FOREIGN KEY (id_template) REFERENCES public.groupscheduletemplates(id_template);


--
-- Name: groupscheduletemplates groupscheduletemplates_id_classtype_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupscheduletemplates
    ADD CONSTRAINT groupscheduletemplates_id_classtype_fkey FOREIGN KEY (id_classtype) REFERENCES public.classtypes(id_classtype);


--
-- Name: groupscheduletemplates groupscheduletemplates_id_hall_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupscheduletemplates
    ADD CONSTRAINT groupscheduletemplates_id_hall_fkey FOREIGN KEY (id_hall) REFERENCES public.halls(id_hall);


--
-- Name: medicalnotes medicalnotes_id_client_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicalnotes
    ADD CONSTRAINT medicalnotes_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.clients(id_client) ON DELETE CASCADE;


--
-- Name: personaltrainings personaltrainings_id_hall_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personaltrainings
    ADD CONSTRAINT personaltrainings_id_hall_fkey FOREIGN KEY (id_hall) REFERENCES public.halls(id_hall);


--
-- Name: personaltrainings personaltrainings_id_sale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personaltrainings
    ADD CONSTRAINT personaltrainings_id_sale_fkey FOREIGN KEY (id_sale) REFERENCES public.sales(id_sale);


--
-- Name: pricelistsubs pricelistsubs_id_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricelistsubs
    ADD CONSTRAINT pricelistsubs_id_item_fkey FOREIGN KEY (id_item) REFERENCES public.pricelist(id_item) ON DELETE CASCADE;


--
-- Name: pt_changelog pt_changelog_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pt_changelog
    ADD CONSTRAINT pt_changelog_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personaltrainings(id_personal) ON DELETE CASCADE;


--
-- Name: pt_timechangedetails pt_timechangedetails_id_ptlog_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pt_timechangedetails
    ADD CONSTRAINT pt_timechangedetails_id_ptlog_fkey FOREIGN KEY (id_ptlog) REFERENCES public.pt_changelog(id_ptlog) ON DELETE CASCADE;


--
-- Name: sales sales_id_client_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_id_client_fkey FOREIGN KEY (id_client) REFERENCES public.clients(id_client);


--
-- Name: sales sales_id_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_id_item_fkey FOREIGN KEY (id_item) REFERENCES public.pricelist(id_item);


--
-- Name: staff staff_id_position_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_id_position_fkey FOREIGN KEY (id_position) REFERENCES public.positions(id_position);


--
-- Name: visits visits_id_hall_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_id_hall_fkey FOREIGN KEY (id_hall) REFERENCES public.halls(id_hall);


--
-- Name: visits visits_id_sale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_id_sale_fkey FOREIGN KEY (id_sale) REFERENCES public.sales(id_sale);


--
-- Name: appliedpromo; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.appliedpromo ENABLE ROW LEVEL SECURITY;

--
-- Name: groupclassbookings client_bookings_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_bookings_access ON public.groupclassbookings TO client_role USING ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: freezinglogs client_freeze_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_freeze_access ON public.freezinglogs TO client_role USING ((id_clientsub IN ( SELECT cs.id_clientsub
   FROM ((public.clientsubscriptions cs
     JOIN public.sales s ON ((cs.id_sale = s.id_sale)))
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_clientsub IN ( SELECT cs.id_clientsub
   FROM ((public.clientsubscriptions cs
     JOIN public.sales s ON ((cs.id_sale = s.id_sale)))
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: medicalnotes client_med_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_med_access ON public.medicalnotes TO client_role USING ((id_client IN ( SELECT clients.id_client
   FROM public.clients
  WHERE ((clients.db_user)::text = SESSION_USER)))) WITH CHECK ((id_client IN ( SELECT clients.id_client
   FROM public.clients
  WHERE ((clients.db_user)::text = SESSION_USER))));


--
-- Name: appliedpromo client_promo_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_promo_access ON public.appliedpromo TO client_role USING ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: personaltrainings client_pt_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_pt_access ON public.personaltrainings TO client_role USING ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: pt_changelog client_ptlog_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_ptlog_access ON public.pt_changelog TO client_role USING ((id_personal IN ( SELECT pt.id_personal
   FROM ((public.personaltrainings pt
     JOIN public.sales s ON ((pt.id_sale = s.id_sale)))
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_personal IN ( SELECT pt.id_personal
   FROM ((public.personaltrainings pt
     JOIN public.sales s ON ((pt.id_sale = s.id_sale)))
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: pt_timechangedetails client_pttime_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_pttime_access ON public.pt_timechangedetails TO client_role USING ((id_ptlog IN ( SELECT cl.id_ptlog
   FROM (((public.pt_changelog cl
     JOIN public.personaltrainings pt ON ((cl.id_personal = pt.id_personal)))
     JOIN public.sales s ON ((pt.id_sale = s.id_sale)))
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_ptlog IN ( SELECT cl.id_ptlog
   FROM (((public.pt_changelog cl
     JOIN public.personaltrainings pt ON ((cl.id_personal = pt.id_personal)))
     JOIN public.sales s ON ((pt.id_sale = s.id_sale)))
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: sales client_sales_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_sales_access ON public.sales TO client_role USING ((id_client IN ( SELECT clients.id_client
   FROM public.clients
  WHERE ((clients.db_user)::text = SESSION_USER)))) WITH CHECK ((id_client IN ( SELECT clients.id_client
   FROM public.clients
  WHERE ((clients.db_user)::text = SESSION_USER))));


--
-- Name: clients client_self_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_self_update ON public.clients FOR UPDATE TO client_role USING (((db_user)::text = SESSION_USER)) WITH CHECK (((db_user)::text = SESSION_USER));


--
-- Name: clients client_self_view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_self_view ON public.clients FOR SELECT TO client_role USING (((db_user)::text = SESSION_USER));


--
-- Name: clientsubscriptions client_subs_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_subs_access ON public.clientsubscriptions TO client_role USING ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER)))) WITH CHECK ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: visits client_visits_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY client_visits_select ON public.visits FOR SELECT TO client_role USING ((id_sale IN ( SELECT s.id_sale
   FROM (public.sales s
     JOIN public.clients c ON ((s.id_client = c.id_client)))
  WHERE ((c.db_user)::text = SESSION_USER))));


--
-- Name: clients; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

--
-- Name: clientsubscriptions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.clientsubscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: clients coach_clients_view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_clients_view ON public.clients FOR SELECT TO coach_role USING (((id_client IN ( SELECT s.id_client
   FROM (((public.sales s
     JOIN public.personaltrainings pt ON ((s.id_sale = pt.id_sale)))
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff st ON ((c.id_staff = st.id_staff)))
  WHERE ((st.db_user)::text = SESSION_USER))) OR (id_client IN ( SELECT sl.id_client
   FROM (((((public.sales sl
     JOIN public.groupclassbookings gcb ON ((sl.id_sale = gcb.id_sale)))
     JOIN public.groupclassinstances gci ON ((gcb.id_instance = gci.id_instance)))
     JOIN public.groupscheduletemplates gst ON ((gci.id_template = gst.id_template)))
     JOIN public.coaches co ON ((gst.id_coach = co.id_coach)))
     JOIN public.staff sta ON ((co.id_staff = sta.id_staff)))
  WHERE ((sta.db_user)::text = SESSION_USER)))));


--
-- Name: groupclassbookings coach_group_bookings_view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_group_bookings_view ON public.groupclassbookings FOR SELECT TO coach_role USING ((id_instance IN ( SELECT gci.id_instance
   FROM (((public.groupclassinstances gci
     JOIN public.groupscheduletemplates gst ON ((gci.id_template = gst.id_template)))
     JOIN public.coaches c ON ((gst.id_coach = c.id_coach)))
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER))));


--
-- Name: medicalnotes coach_medical_view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_medical_view ON public.medicalnotes FOR SELECT TO coach_role USING (((id_client IN ( SELECT s.id_client
   FROM (((public.sales s
     JOIN public.personaltrainings pt ON ((s.id_sale = pt.id_sale)))
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff st ON ((c.id_staff = st.id_staff)))
  WHERE ((st.db_user)::text = SESSION_USER))) OR (id_client IN ( SELECT sl.id_client
   FROM (((((public.sales sl
     JOIN public.groupclassbookings gcb ON ((sl.id_sale = gcb.id_sale)))
     JOIN public.groupclassinstances gci ON ((gcb.id_instance = gci.id_instance)))
     JOIN public.groupscheduletemplates gst ON ((gci.id_template = gst.id_template)))
     JOIN public.coaches co ON ((gst.id_coach = co.id_coach)))
     JOIN public.staff sta ON ((co.id_staff = sta.id_staff)))
  WHERE ((sta.db_user)::text = SESSION_USER)))));


--
-- Name: personaltrainings coach_pt_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_pt_access ON public.personaltrainings TO coach_role USING ((id_coach IN ( SELECT c.id_coach
   FROM (public.coaches c
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER)))) WITH CHECK ((id_coach IN ( SELECT c.id_coach
   FROM (public.coaches c
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER))));


--
-- Name: pt_changelog coach_ptlog_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_ptlog_access ON public.pt_changelog TO coach_role USING ((id_personal IN ( SELECT pt.id_personal
   FROM ((public.personaltrainings pt
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER)))) WITH CHECK ((id_personal IN ( SELECT pt.id_personal
   FROM ((public.personaltrainings pt
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER))));


--
-- Name: pt_timechangedetails coach_pttime_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_pttime_access ON public.pt_timechangedetails TO coach_role USING ((id_ptlog IN ( SELECT cl.id_ptlog
   FROM (((public.pt_changelog cl
     JOIN public.personaltrainings pt ON ((cl.id_personal = pt.id_personal)))
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER)))) WITH CHECK ((id_ptlog IN ( SELECT cl.id_ptlog
   FROM (((public.pt_changelog cl
     JOIN public.personaltrainings pt ON ((cl.id_personal = pt.id_personal)))
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff s ON ((c.id_staff = s.id_staff)))
  WHERE ((s.db_user)::text = SESSION_USER))));


--
-- Name: sales coach_sales_view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY coach_sales_view ON public.sales FOR SELECT TO coach_role USING (((id_sale IN ( SELECT pt.id_sale
   FROM ((public.personaltrainings pt
     JOIN public.coaches c ON ((pt.id_coach = c.id_coach)))
     JOIN public.staff st ON ((c.id_staff = st.id_staff)))
  WHERE ((st.db_user)::text = SESSION_USER))) OR (id_sale IN ( SELECT gcb.id_sale
   FROM ((((public.groupclassbookings gcb
     JOIN public.groupclassinstances gci ON ((gcb.id_instance = gci.id_instance)))
     JOIN public.groupscheduletemplates gst ON ((gci.id_template = gst.id_template)))
     JOIN public.coaches co ON ((gst.id_coach = co.id_coach)))
     JOIN public.staff sta ON ((co.id_staff = sta.id_staff)))
  WHERE ((sta.db_user)::text = SESSION_USER)))));


--
-- Name: freezinglogs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.freezinglogs ENABLE ROW LEVEL SECURITY;

--
-- Name: groupclassbookings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.groupclassbookings ENABLE ROW LEVEL SECURITY;

--
-- Name: personaltrainings guest_pt_view; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY guest_pt_view ON public.personaltrainings FOR SELECT TO guest USING ((trainingstatus = ANY (ARRAY['Completed'::public.activity_status, 'Attended'::public.activity_status])));


--
-- Name: medicalnotes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.medicalnotes ENABLE ROW LEVEL SECURITY;

--
-- Name: personaltrainings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.personaltrainings ENABLE ROW LEVEL SECURITY;

--
-- Name: pt_changelog; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pt_changelog ENABLE ROW LEVEL SECURITY;

--
-- Name: pt_timechangedetails; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pt_timechangedetails ENABLE ROW LEVEL SECURITY;

--
-- Name: sales; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

--
-- Name: groupclassbookings staff_bookings_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_bookings_access ON public.groupclassbookings TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: clients staff_clients_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_clients_access ON public.clients TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: freezinglogs staff_freeze_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_freeze_access ON public.freezinglogs TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: medicalnotes staff_med_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_med_access ON public.medicalnotes TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: appliedpromo staff_promo_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_promo_access ON public.appliedpromo TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: personaltrainings staff_pt_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_pt_access ON public.personaltrainings TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: pt_changelog staff_ptlog_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_ptlog_access ON public.pt_changelog TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: pt_timechangedetails staff_pttime_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_pttime_access ON public.pt_timechangedetails TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: sales staff_sales_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_sales_access ON public.sales TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: clientsubscriptions staff_subs_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_subs_access ON public.clientsubscriptions TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: visits staff_visits_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_visits_access ON public.visits TO director_role, manager_role USING (true) WITH CHECK (true);


--
-- Name: visits; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO director_role;
GRANT USAGE ON SCHEMA public TO manager_role;
GRANT USAGE ON SCHEMA public TO coach_role;
GRANT USAGE ON SCHEMA public TO client_role;
GRANT USAGE ON SCHEMA public TO guest;
GRANT USAGE ON SCHEMA public TO hr_role;


--
-- Name: FUNCTION sp_create_client_user(p_db_user character varying, p_password character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_create_client_user(p_db_user character varying, p_password character varying) TO manager_role;
GRANT ALL ON FUNCTION public.sp_create_client_user(p_db_user character varying, p_password character varying) TO director_role;


--
-- Name: FUNCTION sp_fire_employee(p_staff_id integer, p_fire_date date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_fire_employee(p_staff_id integer, p_fire_date date) TO hr_role;
GRANT ALL ON FUNCTION public.sp_fire_employee(p_staff_id integer, p_fire_date date) TO director_role;


--
-- Name: PROCEDURE sp_freeze_client_subscription(IN p_client_sub_id integer, IN p_freeze_start_date date, IN p_freeze_end_date date, IN p_reason character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.sp_freeze_client_subscription(IN p_client_sub_id integer, IN p_freeze_start_date date, IN p_freeze_end_date date, IN p_reason character varying) TO client_role;


--
-- Name: PROCEDURE sp_unfreeze_client_subscription(IN p_client_sub_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.sp_unfreeze_client_subscription(IN p_client_sub_id integer) TO client_role;


--
-- Name: PROCEDURE sp_book_group_class(IN p_instance_id integer, IN p_sale_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.sp_book_group_class(IN p_instance_id integer, IN p_sale_id integer) TO client_role;
GRANT ALL ON PROCEDURE public.sp_book_group_class(IN p_instance_id integer, IN p_sale_id integer) TO manager_role;


--
-- Name: PROCEDURE sp_cancel_group_booking(IN p_booking_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.sp_cancel_group_booking(IN p_booking_id integer) TO client_role;
GRANT ALL ON PROCEDURE public.sp_cancel_group_booking(IN p_booking_id integer) TO manager_role;


--
-- Name: PROCEDURE sp_generate_weekly_group_instances(IN p_weeks_ahead integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.sp_generate_weekly_group_instances(IN p_weeks_ahead integer) TO director_role;
GRANT ALL ON PROCEDURE public.sp_generate_weekly_group_instances(IN p_weeks_ahead integer) TO manager_role;
GRANT ALL ON PROCEDURE public.sp_generate_weekly_group_instances(IN p_weeks_ahead integer) TO client_role;
GRANT ALL ON PROCEDURE public.sp_generate_weekly_group_instances(IN p_weeks_ahead integer) TO coach_role;


--
-- Name: FUNCTION sp_hire_coach(p_fullname character varying, p_birthdate date, p_phone character varying, p_spec_id integer, p_db_user character varying, p_password character varying, p_bio text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_hire_coach(p_fullname character varying, p_birthdate date, p_phone character varying, p_spec_id integer, p_db_user character varying, p_password character varying, p_bio text) TO hr_role;
GRANT ALL ON FUNCTION public.sp_hire_coach(p_fullname character varying, p_birthdate date, p_phone character varying, p_spec_id integer, p_db_user character varying, p_password character varying, p_bio text) TO director_role;


--
-- Name: FUNCTION sp_hire_manager(p_fullname character varying, p_birthdate date, p_phone character varying, p_db_user character varying, p_password character varying, p_position_name character varying, p_hire_date date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_hire_manager(p_fullname character varying, p_birthdate date, p_phone character varying, p_db_user character varying, p_password character varying, p_position_name character varying, p_hire_date date) TO hr_role;
GRANT ALL ON FUNCTION public.sp_hire_manager(p_fullname character varying, p_birthdate date, p_phone character varying, p_db_user character varying, p_password character varying, p_position_name character varying, p_hire_date date) TO director_role;


--
-- Name: FUNCTION sp_register_client(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying, p_medical_notes text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_register_client(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying, p_medical_notes text) TO guest;
GRANT ALL ON FUNCTION public.sp_register_client(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying, p_medical_notes text) TO manager_role;
GRANT ALL ON FUNCTION public.sp_register_client(p_fullname character varying, p_birthdate date, p_phone character varying, p_gender character varying, p_db_user character varying, p_password character varying, p_item_id integer, p_promo_code character varying, p_medical_notes text) TO director_role;


--
-- Name: TABLE appliedpromo; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.appliedpromo TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.appliedpromo TO manager_role;
GRANT SELECT,INSERT ON TABLE public.appliedpromo TO client_role;


--
-- Name: TABLE classtypes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.classtypes TO director_role;
GRANT SELECT ON TABLE public.classtypes TO manager_role;
GRANT SELECT ON TABLE public.classtypes TO coach_role;
GRANT SELECT ON TABLE public.classtypes TO client_role;
GRANT SELECT ON TABLE public.classtypes TO guest;


--
-- Name: SEQUENCE classtypes_id_classtype_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.classtypes_id_classtype_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.classtypes_id_classtype_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.classtypes_id_classtype_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.classtypes_id_classtype_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.classtypes_id_classtype_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.classtypes_id_classtype_seq TO guest;


--
-- Name: TABLE clients; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.clients TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clients TO manager_role;
GRANT SELECT ON TABLE public.clients TO coach_role;
GRANT SELECT ON TABLE public.clients TO client_role;


--
-- Name: COLUMN clients.fullname; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(fullname) ON TABLE public.clients TO client_role;


--
-- Name: COLUMN clients.phone; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(phone) ON TABLE public.clients TO client_role;


--
-- Name: SEQUENCE clients_id_client_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.clients_id_client_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.clients_id_client_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.clients_id_client_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.clients_id_client_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.clients_id_client_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.clients_id_client_seq TO guest;


--
-- Name: TABLE clientsubscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.clientsubscriptions TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clientsubscriptions TO manager_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.clientsubscriptions TO client_role;


--
-- Name: SEQUENCE clientsubscriptions_id_clientsub_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.clientsubscriptions_id_clientsub_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.clientsubscriptions_id_clientsub_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.clientsubscriptions_id_clientsub_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.clientsubscriptions_id_clientsub_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.clientsubscriptions_id_clientsub_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.clientsubscriptions_id_clientsub_seq TO guest;


--
-- Name: TABLE coaches; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.coaches TO director_role;
GRANT SELECT ON TABLE public.coaches TO manager_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.coaches TO hr_role;
GRANT SELECT ON TABLE public.coaches TO coach_role;
GRANT SELECT ON TABLE public.coaches TO client_role;
GRANT SELECT ON TABLE public.coaches TO guest;


--
-- Name: SEQUENCE coaches_id_coach_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.coaches_id_coach_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.coaches_id_coach_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.coaches_id_coach_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.coaches_id_coach_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.coaches_id_coach_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.coaches_id_coach_seq TO guest;


--
-- Name: TABLE freezinglogs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.freezinglogs TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.freezinglogs TO manager_role;
GRANT SELECT,INSERT ON TABLE public.freezinglogs TO client_role;


--
-- Name: SEQUENCE freezinglogs_id_freezing_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.freezinglogs_id_freezing_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.freezinglogs_id_freezing_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.freezinglogs_id_freezing_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.freezinglogs_id_freezing_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.freezinglogs_id_freezing_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.freezinglogs_id_freezing_seq TO guest;


--
-- Name: TABLE groupclassbookings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.groupclassbookings TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.groupclassbookings TO manager_role;
GRANT SELECT ON TABLE public.groupclassbookings TO coach_role;
GRANT SELECT,INSERT ON TABLE public.groupclassbookings TO client_role;


--
-- Name: COLUMN groupclassbookings.bookingstatus; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(bookingstatus) ON TABLE public.groupclassbookings TO client_role;


--
-- Name: SEQUENCE groupclassbookings_id_booking_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.groupclassbookings_id_booking_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassbookings_id_booking_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassbookings_id_booking_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassbookings_id_booking_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassbookings_id_booking_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassbookings_id_booking_seq TO guest;


--
-- Name: TABLE groupclassinstances; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.groupclassinstances TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.groupclassinstances TO manager_role;
GRANT SELECT ON TABLE public.groupclassinstances TO coach_role;
GRANT SELECT ON TABLE public.groupclassinstances TO client_role;
GRANT SELECT ON TABLE public.groupclassinstances TO guest;


--
-- Name: COLUMN groupclassinstances.classstatus; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(classstatus) ON TABLE public.groupclassinstances TO coach_role;


--
-- Name: COLUMN groupclassinstances.actualattendance; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(actualattendance) ON TABLE public.groupclassinstances TO coach_role;


--
-- Name: SEQUENCE groupclassinstances_id_instance_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.groupclassinstances_id_instance_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassinstances_id_instance_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassinstances_id_instance_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassinstances_id_instance_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassinstances_id_instance_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupclassinstances_id_instance_seq TO guest;


--
-- Name: TABLE groupscheduletemplates; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.groupscheduletemplates TO director_role;
GRANT SELECT ON TABLE public.groupscheduletemplates TO manager_role;
GRANT SELECT ON TABLE public.groupscheduletemplates TO coach_role;
GRANT SELECT ON TABLE public.groupscheduletemplates TO client_role;
GRANT SELECT ON TABLE public.groupscheduletemplates TO guest;


--
-- Name: SEQUENCE groupscheduletemplates_id_template_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.groupscheduletemplates_id_template_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupscheduletemplates_id_template_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupscheduletemplates_id_template_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupscheduletemplates_id_template_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupscheduletemplates_id_template_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.groupscheduletemplates_id_template_seq TO guest;


--
-- Name: TABLE halls; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.halls TO director_role;
GRANT SELECT ON TABLE public.halls TO manager_role;
GRANT SELECT ON TABLE public.halls TO coach_role;
GRANT SELECT ON TABLE public.halls TO client_role;
GRANT SELECT ON TABLE public.halls TO guest;


--
-- Name: SEQUENCE halls_id_hall_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.halls_id_hall_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.halls_id_hall_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.halls_id_hall_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.halls_id_hall_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.halls_id_hall_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.halls_id_hall_seq TO guest;


--
-- Name: TABLE medicalnotes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.medicalnotes TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.medicalnotes TO manager_role;
GRANT SELECT ON TABLE public.medicalnotes TO coach_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.medicalnotes TO client_role;


--
-- Name: TABLE personaltrainings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.personaltrainings TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.personaltrainings TO manager_role;
GRANT SELECT ON TABLE public.personaltrainings TO coach_role;
GRANT SELECT,INSERT ON TABLE public.personaltrainings TO client_role;
GRANT SELECT ON TABLE public.personaltrainings TO guest;


--
-- Name: COLUMN personaltrainings.trainingstatus; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(trainingstatus) ON TABLE public.personaltrainings TO coach_role;
GRANT UPDATE(trainingstatus) ON TABLE public.personaltrainings TO client_role;


--
-- Name: SEQUENCE personaltrainings_id_personal_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.personaltrainings_id_personal_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.personaltrainings_id_personal_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.personaltrainings_id_personal_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.personaltrainings_id_personal_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.personaltrainings_id_personal_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.personaltrainings_id_personal_seq TO guest;


--
-- Name: TABLE positions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.positions TO director_role;
GRANT SELECT ON TABLE public.positions TO manager_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.positions TO hr_role;


--
-- Name: SEQUENCE positions_id_position_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.positions_id_position_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.positions_id_position_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.positions_id_position_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.positions_id_position_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.positions_id_position_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.positions_id_position_seq TO guest;


--
-- Name: TABLE pricelist; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pricelist TO director_role;
GRANT SELECT ON TABLE public.pricelist TO manager_role;
GRANT SELECT ON TABLE public.pricelist TO client_role;
GRANT SELECT ON TABLE public.pricelist TO guest;


--
-- Name: SEQUENCE pricelist_id_item_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.pricelist_id_item_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.pricelist_id_item_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.pricelist_id_item_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.pricelist_id_item_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.pricelist_id_item_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.pricelist_id_item_seq TO guest;


--
-- Name: TABLE pricelistsubs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pricelistsubs TO director_role;
GRANT SELECT ON TABLE public.pricelistsubs TO manager_role;
GRANT SELECT ON TABLE public.pricelistsubs TO client_role;
GRANT SELECT ON TABLE public.pricelistsubs TO guest;


--
-- Name: TABLE promocodes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.promocodes TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.promocodes TO manager_role;
GRANT SELECT ON TABLE public.promocodes TO client_role;


--
-- Name: SEQUENCE promocodes_id_promo_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.promocodes_id_promo_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.promocodes_id_promo_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.promocodes_id_promo_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.promocodes_id_promo_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.promocodes_id_promo_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.promocodes_id_promo_seq TO guest;


--
-- Name: TABLE pt_changelog; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pt_changelog TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pt_changelog TO manager_role;
GRANT SELECT,INSERT ON TABLE public.pt_changelog TO coach_role;
GRANT SELECT,INSERT ON TABLE public.pt_changelog TO client_role;


--
-- Name: SEQUENCE pt_changelog_id_ptlog_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.pt_changelog_id_ptlog_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.pt_changelog_id_ptlog_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.pt_changelog_id_ptlog_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.pt_changelog_id_ptlog_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.pt_changelog_id_ptlog_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.pt_changelog_id_ptlog_seq TO guest;


--
-- Name: TABLE pt_timechangedetails; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pt_timechangedetails TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pt_timechangedetails TO manager_role;
GRANT SELECT,INSERT ON TABLE public.pt_timechangedetails TO coach_role;
GRANT SELECT,INSERT ON TABLE public.pt_timechangedetails TO client_role;


--
-- Name: TABLE sales; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sales TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sales TO manager_role;
GRANT SELECT ON TABLE public.sales TO coach_role;
GRANT SELECT,INSERT ON TABLE public.sales TO client_role;


--
-- Name: SEQUENCE sales_id_sale_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sales_id_sale_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.sales_id_sale_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.sales_id_sale_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.sales_id_sale_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.sales_id_sale_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.sales_id_sale_seq TO guest;


--
-- Name: TABLE specializations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.specializations TO director_role;
GRANT SELECT ON TABLE public.specializations TO manager_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.specializations TO hr_role;
GRANT SELECT ON TABLE public.specializations TO coach_role;
GRANT SELECT ON TABLE public.specializations TO client_role;
GRANT SELECT ON TABLE public.specializations TO guest;


--
-- Name: SEQUENCE specializations_id_spec_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.specializations_id_spec_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.specializations_id_spec_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.specializations_id_spec_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.specializations_id_spec_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.specializations_id_spec_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.specializations_id_spec_seq TO guest;


--
-- Name: TABLE staff; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.staff TO director_role;
GRANT SELECT ON TABLE public.staff TO manager_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.staff TO hr_role;
GRANT SELECT ON TABLE public.staff TO coach_role;
GRANT SELECT ON TABLE public.staff TO client_role;
GRANT SELECT ON TABLE public.staff TO guest;


--
-- Name: SEQUENCE staff_id_staff_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.staff_id_staff_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.staff_id_staff_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.staff_id_staff_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.staff_id_staff_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.staff_id_staff_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.staff_id_staff_seq TO guest;


--
-- Name: TABLE v_coachstats; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_coachstats TO director_role;


--
-- Name: TABLE v_groupindividualclientsshare; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_groupindividualclientsshare TO director_role;
GRANT SELECT ON TABLE public.v_groupindividualclientsshare TO manager_role;


--
-- Name: TABLE visits; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.visits TO director_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.visits TO manager_role;
GRANT SELECT ON TABLE public.visits TO client_role;


--
-- Name: SEQUENCE visits_id_visit_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.visits_id_visit_seq TO director_role;
GRANT SELECT,USAGE ON SEQUENCE public.visits_id_visit_seq TO manager_role;
GRANT SELECT,USAGE ON SEQUENCE public.visits_id_visit_seq TO hr_role;
GRANT SELECT,USAGE ON SEQUENCE public.visits_id_visit_seq TO coach_role;
GRANT SELECT,USAGE ON SEQUENCE public.visits_id_visit_seq TO client_role;
GRANT SELECT,USAGE ON SEQUENCE public.visits_id_visit_seq TO guest;


--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE postgres;
--
-- Name: postgres; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE postgres OWNER TO postgres;

\connect postgres

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

