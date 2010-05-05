<%

Private Const bits_to_a_byte = 8
Private Const bytes_to_a_word = 4
Private Const bits_to_a_word = 32
Private m_lonbits(30)
Private m_l2power(30)

Private Function lshift(lvalue, ishiftbits)
    If ishiftbits = 0 Then
        lshift = lvalue
        Exit Function
    ElseIf ishiftbits = 31 Then
        If lvalue And 1 Then
            lshift = &H80000000
        Else
            lshift = 0
        End If
        Exit Function
    ElseIf ishiftbits < 0 Or ishiftbits > 31 Then
        Err.Raise 6
    End If
    If (lvalue And m_l2power(31 - ishiftbits)) Then
        lshift = ((lvalue And m_lonbits(31 - (ishiftbits + 1))) * m_l2power(ishiftbits)) Or &H80000000
    Else
        lshift = ((lvalue And m_lonbits(31 - ishiftbits)) * m_l2power(ishiftbits))
    End If
End Function

Private Function rshift(lvalue, ishiftbits)
    If ishiftbits = 0 Then
        rshift = lvalue
        Exit Function
    ElseIf ishiftbits = 31 Then
        If lvalue And &H80000000 Then
            rshift = 1
        Else
            rshift = 0
        End If
        Exit Function
    ElseIf ishiftbits < 0 Or ishiftbits > 31 Then
        Err.Raise 6
    End If
    rshift = (lvalue And &H7FFFFFFE) \ m_l2power(ishiftbits)
    If (lvalue And &H80000000) Then
        rshift = (rshift Or (&H40000000 \ m_l2power(ishiftbits - 1)))
    End If
End Function

Private Function rotateleft(lvalue, ishiftbits)
    rotateleft = lshift(lvalue, ishiftbits) Or rshift(lvalue, (32 - ishiftbits))
End Function

Private Function addunsigned(lx, ly)
    Dim lx4
    Dim ly4
    Dim lx8
    Dim ly8
    Dim lresult
    lx8 = lx And &H80000000
    ly8 = ly And &H80000000
    lx4 = lx And &H40000000
    ly4 = ly And &H40000000
    lresult = (lx And &H3FFFFFFF) + (ly And &H3FFFFFFF)
    If lx4 And ly4 Then
        lresult = lresult Xor &H80000000 Xor lx8 Xor ly8
    ElseIf lx4 Or ly4 Then
        If lresult And &H40000000 Then
            lresult = lresult Xor &HC0000000 Xor lx8 Xor ly8
        Else
            lresult = lresult Xor &H40000000 Xor lx8 Xor ly8
        End If
    Else
        lresult = lresult Xor lx8 Xor ly8
    End If
    addunsigned = lresult
End Function

Private Function md5_f(x, y, z)
    md5_f = (x And y) Or ((Not x) And z)
End Function

Private Function md5_g(x, y, z)
    md5_g = (x And z) Or (y And (Not z))
End Function

Private Function md5_h(x, y, z)
    md5_h = (x Xor y Xor z)
End Function

Private Function md5_i(x, y, z)
    md5_i = (y Xor (x Or (Not z)))
End Function

Private Sub md5_ff(a, b, c, d, x, s, ac)
    a = addunsigned(a, addunsigned(addunsigned(md5_f(b, c, d), x), ac))
    a = rotateleft(a, s)
    a = addunsigned(a, b)
End Sub

Private Sub md5_gg(a, b, c, d, x, s, ac)
    a = addunsigned(a, addunsigned(addunsigned(md5_g(b, c, d), x), ac))
    a = rotateleft(a, s)
    a = addunsigned(a, b)
End Sub

Private Sub md5_hh(a, b, c, d, x, s, ac)
    a = addunsigned(a, addunsigned(addunsigned(md5_h(b, c, d), x), ac))
    a = rotateleft(a, s)
    a = addunsigned(a, b)
End Sub

Private Sub md5_ii(a, b, c, d, x, s, ac)
    a = addunsigned(a, addunsigned(addunsigned(md5_i(b, c, d), x), ac))
    a = rotateleft(a, s)
    a = addunsigned(a, b)
End Sub

Private Function converttowordarray(smessage)
    Dim lmessagelength
    Dim lnumberofwords
    Dim lwordarray()
    Dim lbyteposition
    Dim lbytecount
    Dim lwordcount
    Const modulus_bits = 512
    Const congruent_bits = 448

    lmessagelength = Len(smessage)
    lnumberofwords = (((lmessagelength + ((modulus_bits - congruent_bits) \ bits_to_a_byte)) \ (modulus_bits \ bits_to_a_byte)) + 1) * (modulus_bits \ bits_to_a_word)
    ReDim lwordarray(lnumberofwords - 1)
    lbyteposition = 0
    lbytecount = 0

    Do Until lbytecount >= lmessagelength
        lwordcount = lbytecount \ bytes_to_a_word
        lbyteposition = (lbytecount Mod bytes_to_a_word) * bits_to_a_byte
        lwordarray(lwordcount) = lwordarray(lwordcount) Or lshift(Asc(Mid(smessage, lbytecount + 1, 1)), lbyteposition)
        lbytecount = lbytecount + 1
    Loop

    lwordcount = lbytecount \ bytes_to_a_word
    lbyteposition = (lbytecount Mod bytes_to_a_word) * bits_to_a_byte
    lwordarray(lwordcount) = lwordarray(lwordcount) Or lshift(&H80, lbyteposition)
    lwordarray(lnumberofwords - 2) = lshift(lmessagelength, 3)
    lwordarray(lnumberofwords - 1) = rshift(lmessagelength, 29)
    converttowordarray = lwordarray
End Function

Private Function wordtohex(lvalue)
    Dim lbyte
    Dim lcount
    For lcount = 0 To 3
        lbyte = rshift(lvalue, lcount * bits_to_a_byte) And m_lonbits(bits_to_a_byte - 1)
        wordtohex = wordtohex & Right("0" & Hex(lbyte), 2)
    Next
End Function

Public Function MD5(smessage)
    m_lonbits(0) = CLng(1)
    m_lonbits(1) = CLng(3)
    m_lonbits(2) = CLng(7)
    m_lonbits(3) = CLng(15)
    m_lonbits(4) = CLng(31)
    m_lonbits(5) = CLng(63)
    m_lonbits(6) = CLng(127)
    m_lonbits(7) = CLng(255)
    m_lonbits(8) = CLng(511)
    m_lonbits(9) = CLng(1023)
    m_lonbits(10) = CLng(2047)
    m_lonbits(11) = CLng(4095)
    m_lonbits(12) = CLng(8191)
    m_lonbits(13) = CLng(16383)
    m_lonbits(14) = CLng(32767)
    m_lonbits(15) = CLng(65535)
    m_lonbits(16) = CLng(131071)
    m_lonbits(17) = CLng(262143)
    m_lonbits(18) = CLng(524287)
    m_lonbits(19) = CLng(1048575)
    m_lonbits(20) = CLng(2097151)
    m_lonbits(21) = CLng(4194303)
    m_lonbits(22) = CLng(8388607)
    m_lonbits(23) = CLng(16777215)
    m_lonbits(24) = CLng(33554431)
    m_lonbits(25) = CLng(67108863)
    m_lonbits(26) = CLng(134217727)
    m_lonbits(27) = CLng(268435455)
    m_lonbits(28) = CLng(536870911)
    m_lonbits(29) = CLng(1073741823)
    m_lonbits(30) = CLng(2147483647)
    m_l2power(0) = CLng(1)
    m_l2power(1) = CLng(2)
    m_l2power(2) = CLng(4)
    m_l2power(3) = CLng(8)
    m_l2power(4) = CLng(16)
    m_l2power(5) = CLng(32)
    m_l2power(6) = CLng(64)
    m_l2power(7) = CLng(128)
    m_l2power(8) = CLng(256)
    m_l2power(9) = CLng(512)
    m_l2power(10) = CLng(1024)
    m_l2power(11) = CLng(2048)
    m_l2power(12) = CLng(4096)
    m_l2power(13) = CLng(8192)
    m_l2power(14) = CLng(16384)
    m_l2power(15) = CLng(32768)
    m_l2power(16) = CLng(65536)
    m_l2power(17) = CLng(131072)
    m_l2power(18) = CLng(262144)
    m_l2power(19) = CLng(524288)
    m_l2power(20) = CLng(1048576)
    m_l2power(21) = CLng(2097152)
    m_l2power(22) = CLng(4194304)
    m_l2power(23) = CLng(8388608)
    m_l2power(24) = CLng(16777216)
    m_l2power(25) = CLng(33554432)
    m_l2power(26) = CLng(67108864)
    m_l2power(27) = CLng(134217728)
    m_l2power(28) = CLng(268435456)
    m_l2power(29) = CLng(536870912)
    m_l2power(30) = CLng(1073741824)

    Dim x
    Dim k
    Dim aa
    Dim bb
    Dim cc
    Dim dd
    Dim a
    Dim b
    Dim c
    Dim d
    Const s11 = 7
    Const s12 = 12
    Const s13 = 17
    Const s14 = 22
    Const s21 = 5
    Const s22 = 9
    Const s23 = 14
    Const s24 = 20
    Const s31 = 4
    Const s32 = 11
    Const s33 = 16
    Const s34 = 23
    Const s41 = 6
    Const s42 = 10
    Const s43 = 15
    Const s44 = 21

    x = converttowordarray(smessage)
    a = &H67452301
    b = &HEFCDAB89
    c = &H98BADCFE
    d = &H10325476

    For k = 0 To UBound(x) Step 16
        aa = a
        bb = b
        cc = c
        dd = d
        md5_ff a, b, c, d, x(k + 0), s11, &HD76AA478
        md5_ff d, a, b, c, x(k + 1), s12, &HE8C7B756
        md5_ff c, d, a, b, x(k + 2), s13, &H242070DB
        md5_ff b, c, d, a, x(k + 3), s14, &HC1BDCEEE
        md5_ff a, b, c, d, x(k + 4), s11, &HF57C0FAF
        md5_ff d, a, b, c, x(k + 5), s12, &H4787C62A
        md5_ff c, d, a, b, x(k + 6), s13, &HA8304613
        md5_ff b, c, d, a, x(k + 7), s14, &HFD469501
        md5_ff a, b, c, d, x(k + 8), s11, &H698098D8
        md5_ff d, a, b, c, x(k + 9), s12, &H8B44F7AF
        md5_ff c, d, a, b, x(k + 10), s13, &HFFFF5BB1
        md5_ff b, c, d, a, x(k + 11), s14, &H895CD7BE
        md5_ff a, b, c, d, x(k + 12), s11, &H6B901122
        md5_ff d, a, b, c, x(k + 13), s12, &HFD987193
        md5_ff c, d, a, b, x(k + 14), s13, &HA679438E
        md5_ff b, c, d, a, x(k + 15), s14, &H49B40821

        md5_gg a, b, c, d, x(k + 1), s21, &HF61E2562
        md5_gg d, a, b, c, x(k + 6), s22, &HC040B340
        md5_gg c, d, a, b, x(k + 11), s23, &H265E5A51
        md5_gg b, c, d, a, x(k + 0), s24, &HE9B6C7AA
        md5_gg a, b, c, d, x(k + 5), s21, &HD62F105D
        md5_gg d, a, b, c, x(k + 10), s22, &H2441453
        md5_gg c, d, a, b, x(k + 15), s23, &HD8A1E681
        md5_gg b, c, d, a, x(k + 4), s24, &HE7D3FBC8
        md5_gg a, b, c, d, x(k + 9), s21, &H21E1CDE6
        md5_gg d, a, b, c, x(k + 14), s22, &HC33707D6
        md5_gg c, d, a, b, x(k + 3), s23, &HF4D50D87
        md5_gg b, c, d, a, x(k + 8), s24, &H455A14ED
        md5_gg a, b, c, d, x(k + 13), s21, &HA9E3E905
        md5_gg d, a, b, c, x(k + 2), s22, &HFCEFA3F8
        md5_gg c, d, a, b, x(k + 7), s23, &H676F02D9
        md5_gg b, c, d, a, x(k + 12), s24, &H8D2A4C8A

        md5_hh a, b, c, d, x(k + 5), s31, &HFFFA3942
        md5_hh d, a, b, c, x(k + 8), s32, &H8771F681
        md5_hh c, d, a, b, x(k + 11), s33, &H6D9D6122
        md5_hh b, c, d, a, x(k + 14), s34, &HFDE5380C
        md5_hh a, b, c, d, x(k + 1), s31, &HA4BEEA44
        md5_hh d, a, b, c, x(k + 4), s32, &H4BDECFA9
        md5_hh c, d, a, b, x(k + 7), s33, &HF6BB4B60
        md5_hh b, c, d, a, x(k + 10), s34, &HBEBFBC70
        md5_hh a, b, c, d, x(k + 13), s31, &H289B7EC6
        md5_hh d, a, b, c, x(k + 0), s32, &HEAA127FA
        md5_hh c, d, a, b, x(k + 3), s33, &HD4EF3085
        md5_hh b, c, d, a, x(k + 6), s34, &H4881D05
        md5_hh a, b, c, d, x(k + 9), s31, &HD9D4D039
        md5_hh d, a, b, c, x(k + 12), s32, &HE6DB99E5
        md5_hh c, d, a, b, x(k + 15), s33, &H1FA27CF8
        md5_hh b, c, d, a, x(k + 2), s34, &HC4AC5665

        md5_ii a, b, c, d, x(k + 0), s41, &HF4292244
        md5_ii d, a, b, c, x(k + 7), s42, &H432AFF97
        md5_ii c, d, a, b, x(k + 14), s43, &HAB9423A7
        md5_ii b, c, d, a, x(k + 5), s44, &HFC93A039
        md5_ii a, b, c, d, x(k + 12), s41, &H655B59C3
        md5_ii d, a, b, c, x(k + 3), s42, &H8F0CCC92
        md5_ii c, d, a, b, x(k + 10), s43, &HFFEFF47D
        md5_ii b, c, d, a, x(k + 1), s44, &H85845DD1
        md5_ii a, b, c, d, x(k + 8), s41, &H6FA87E4F
        md5_ii d, a, b, c, x(k + 15), s42, &HFE2CE6E0
        md5_ii c, d, a, b, x(k + 6), s43, &HA3014314
        md5_ii b, c, d, a, x(k + 13), s44, &H4E0811A1
        md5_ii a, b, c, d, x(k + 4), s41, &HF7537E82
        md5_ii d, a, b, c, x(k + 11), s42, &HBD3AF235
        md5_ii c, d, a, b, x(k + 2), s43, &H2AD7D2BB
        md5_ii b, c, d, a, x(k + 9), s44, &HEB86D391

        a = addunsigned(a, aa)
        b = addunsigned(b, bb)
        c = addunsigned(c, cc)
        d = addunsigned(d, dd)
    Next

    MD5 = LCase(wordtohex(a) & wordtohex(b) & wordtohex(c) & wordtohex(d))
End Function
%>