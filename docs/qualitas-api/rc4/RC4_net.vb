Option Explicit On 

Imports System.IO
Imports System.Text
Imports Microsoft.VisualBasic.VBMath
Public Class RC4_net

#Region "Const"
    Private _version As String = "1.0.1"
#End Region

#Region "Private var"
    Private S(255) As Integer
    Private cls_Key As String
#End Region

#Region "Property"
    Private Property Key() As String
        Get
            Return cls_Key
        End Get
        Set(ByVal Key As String)
            cls_Key = Key
        End Set
    End Property

    Private ReadOnly Property Version() As String
        Get
            Return _version
        End Get
    End Property
#End Region

    Public Sub New()

    End Sub

    Private Sub New(ByVal Key As String)
        Me.Key = Key
    End Sub

    Private Function Crypt(ByVal Param As String) As String
        Dim ParamLen As Integer = Param.Length
        Dim C As Integer
        Dim T As Integer
        Dim i As Integer
        Dim j As Integer

        Dim oStringBuilder As New StringBuilder

        CreateKeyArray()

        For C = 0 To ParamLen - 1
            i = (i + 1) And 255
            j = (j + S(i)) And 255
            T = S(i)
            S(i) = S(j)
            S(j) = T

            T = (S(i) + S(j)) And 255

            oStringBuilder.Append(Chr(Asc(Param.Substring(C, 1)) Xor S(T)))
        Next C

        Return oStringBuilder.ToString
    End Function

    Private Overloads Function CryptFile(ByVal FilePath As String) As String
        Dim oFileInfo As New FileInfo(FilePath)

        If oFileInfo.Exists Then
            Dim oFileStream As New FileStream(FilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
            Dim oFileReader As New StreamReader(oFileStream, System.Text.Encoding.Default)

            If oFileStream.CanRead Then
                Dim FileContent As String = oFileReader.ReadToEnd
                Dim FileLen As Int32 = FileContent.Length
                Dim C As Integer
                Dim T As Integer
                Dim i As Integer
                Dim j As Integer

                Dim oStringBuilder As New StringBuilder

                CreateKeyArray()

                For C = 0 To FileLen - 1
                    i = (i + 1) And 255
                    j = (j + S(i)) And 255
                    T = S(i)
                    S(i) = S(j)
                    S(j) = T

                    T = (S(i) + S(j)) And 255

                    oStringBuilder.Append(Chr(Asc(FileContent.Substring(C, 1)) Xor S(T)))
                Next C

                Return oStringBuilder.ToString
            Else
                Throw New Exception("Impossible de lire le fichier " & FilePath)

            End If
        Else
            Throw New Exception("Impossible de trouver le fichier " & FilePath)
        End If
    End Function

    Private Overloads Function CryptFile(ByVal FilePath As String, ByVal OutPutFile As String) As Long
        Dim oFileInfo As New FileInfo(FilePath)

        If oFileInfo.Exists Then
            Dim oFileStream As New FileStream(FilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
            Dim oFileReader As New StreamReader(oFileStream, System.Text.Encoding.Default)

            If oFileStream.CanRead Then
                Dim FileContent As String = oFileReader.ReadToEnd
                oFileStream.Close()
                oFileReader.Close()

                Dim ParamLen As Int32 = FileContent.Length
                Dim C As Integer
                Dim T As Integer
                Dim i As Integer
                Dim j As Integer

                Dim oStringBuilder As New StringBuilder

                CreateKeyArray()

                For C = 0 To ParamLen - 1
                    i = (i + 1) And 255
                    j = (j + S(i)) And 255
                    T = S(i)
                    S(i) = S(j)
                    S(j) = T

                    T = (S(i) + S(j)) And 255

                    oStringBuilder.Append(Chr(Asc(FileContent.Substring(C, 1)) Xor S(T)))
                Next C

                Dim oWriteStream As New FileStream(OutPutFile, FileMode.Create, FileAccess.Write, FileShare.ReadWrite)
                Dim oFileWriter As New StreamWriter(oWriteStream, System.Text.Encoding.Default)

                Try
                    oFileWriter.Write(oStringBuilder.ToString)
                Catch err As Exception
                    Throw New Exception("Impossible d'écrire le fichier de sortie " & OutPutFile)
                End Try

                oFileWriter.Close()

                Return 0

            Else
                Throw New Exception("Impossible de lire le fichier " & FilePath)
            End If
        Else
            Throw New Exception("Impossible de trouver le fichier " & FilePath)
        End If
    End Function

    Private Function Decrypt(ByVal Param As String) As String



        Dim ParamLen As Integer = Len(Param)
        Dim C As Integer
        Dim T As Integer
        Dim i As Integer
        Dim j As Integer

        Dim oStringBuilder As New StringBuilder

        CreateKeyArray()

        For C = 0 To ParamLen - 1
            i = (i + 1) And 255
            j = (j + S(i)) And 255
            T = S(i)
            S(i) = S(j)
            S(j) = T

            T = (S(i) + S(j)) And 255

            oStringBuilder.Append(Chr(Asc(Param.Substring(C, 1)) Xor S(T)))
        Next C
        Return oStringBuilder.ToString
    End Function

    Private Overloads Function DecryptFile(ByVal FilePath As String) As String

        Dim oFileInfo As New FileInfo(FilePath)

        If oFileInfo.Exists Then
            Dim oFileStream As New FileStream(FilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
            Dim oFileReader As New StreamReader(oFileStream, System.Text.Encoding.Default)

            If oFileStream.CanRead Then
                Dim FileContent As String = oFileReader.ReadToEnd
                Dim FileLen As Int32 = FileContent.Length
                Dim C As Integer
                Dim T As Integer
                Dim i As Integer
                Dim j As Integer

                Dim oStringBuilder As New StringBuilder

                CreateKeyArray()

                For C = 0 To FileLen - 1
                    i = (i + 1) And 255
                    j = (j + S(i)) And 255
                    T = S(i)
                    S(i) = S(j)
                    S(j) = T

                    T = (S(i) + S(j)) And 255

                    oStringBuilder.Append(Chr(Asc(FileContent.Substring(C, 1)) Xor S(T)))
                Next C
                Return oStringBuilder.ToString
            Else
                Throw New Exception("Impossible de lire le fichier " & FilePath)
            End If
        Else
            Throw New Exception("Impossible de trouver le fichier " & FilePath)
        End If
    End Function

    Private Overloads Function DecryptFile(ByVal FilePath As String, ByVal OutPutFile As String) As Long

        Dim oFileInfo As New FileInfo(FilePath)

        If oFileInfo.Exists Then
            Dim oFileStream As New FileStream(FilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
            Dim oFileReader As New StreamReader(oFileStream, System.Text.Encoding.Default)

            If oFileStream.CanRead Then
                Dim FileContent As String = oFileReader.ReadToEnd
                Dim FileLen As Int32 = FileContent.Length
                Dim C As Integer
                Dim T As Integer
                Dim i As Integer
                Dim j As Integer

                Dim oStringBuilder As New StringBuilder

                CreateKeyArray()

                For C = 0 To FileLen - 1
                    i = (i + 1) And 255
                    j = (j + S(i)) And 255
                    T = S(i)
                    S(i) = S(j)
                    S(j) = T

                    T = (S(i) + S(j)) And 255

                    oStringBuilder.Append(Chr(Asc(FileContent.Substring(C, 1)) Xor S(T)))
                Next C

                Dim oWriteStream As New FileStream(OutPutFile, FileMode.Create, FileAccess.Write, FileShare.None)
                Dim oFileWriter As New StreamWriter(oWriteStream, System.Text.Encoding.Default)

                Try
                    oFileWriter.Write(oStringBuilder.ToString)
                Catch err As Exception
                    Throw New Exception("Impossible d'écrire le fichier de sortie " & OutPutFile)
                End Try
                oFileWriter.Close()
                Return 0
            Else
                Throw New Exception("Impossible de lire le fichier " & FilePath)
            End If
        Else
            Throw New Exception("Impossible de trouver le fichier " & FilePath)
        End If
    End Function

    Private Sub CreateKeyArray()
        Dim KeyLen As Integer
        Dim T As Integer
        Dim i As Integer = 0
        Dim j As Integer = 0
        Dim lItem As Integer

        If Key.Trim.Length > 0 Then

            KeyLen = cls_Key.Length

            For i = 0 To 255
                S(i) = i
            Next i

            For i = 0 To 255
                j = (j + S(i) + Asc(cls_Key.Substring(i Mod KeyLen, 1)) And 255)
                T = S(i)
                S(i) = S(j)
                S(j) = T
            Next i
            i = 0
            j = 0
        Else
            Throw New System.ArgumentException("La clef est vide")
        End If

    End Sub

    Private Overloads Function GenerateKey() As String
        Dim keyBuffer As New StringBuilder
        Dim KeyLen As Short = 255
        Dim i As Integer
        Randomize(Now.Millisecond)
        Do Until i >= KeyLen
            keyBuffer.Append(Chr(CInt(Rnd(255))))
            i += 1
        Loop
        Me.Key = keyBuffer.ToString
        Return keyBuffer.ToString
    End Function

    Private Overloads Function GenerateKey(ByVal KeyLen As Integer) As String
        Dim keyBuffer As New StringBuilder
        Dim i As Integer

        Randomize(Now.Millisecond)

        Do Until i >= KeyLen
            keyBuffer.Append(Chr(CInt(Rnd(255))))
            i += 1
        Loop

        Me.Key = keyBuffer.ToString
        Return keyBuffer.ToString

    End Function

    Private Overloads Function GenerateKey(ByVal KeyLen As Integer, ByVal Readable As Boolean) As String
        Dim keyBuffer As New StringBuilder
        Dim AvailableChar As String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        Dim lenAvailableChar As Integer = AvailableChar.Length - 1
        Dim i As Integer

        Randomize(Now.Millisecond)

        If Readable = True Then
            Do Until i >= KeyLen
                keyBuffer.Append(AvailableChar.Substring(CType(Rnd(lenAvailableChar), Integer), 1))
                i += 1
            Loop
        Else
            Do Until i >= KeyLen
                keyBuffer.Append(Chr(CInt(Rnd(255))))
                i += 1
            Loop
        End If
        Me.Key = keyBuffer.ToString
        Return keyBuffer.ToString

    End Function

    Private Overloads Function GenerateKey(ByVal KeyLen As Integer, ByVal AvailableChar As String) As String
        Dim keyBuffer As New StringBuilder
        Dim lenAvailableChar As Integer = AvailableChar.Length - 1
        Dim i As Integer

        Randomize(Now.Millisecond)

        Do Until i >= KeyLen
            keyBuffer.Append(AvailableChar.Substring(CType(Rnd(lenAvailableChar), Integer), 1))
            i += 1
        Loop

        Me.Key = keyBuffer.ToString
        Return keyBuffer.ToString

    End Function
    Private Function ConvToHex(ByVal x As Integer) As String
        If x > 9 Then
            ConvToHex = Chr(x + 55)
        Else
            ConvToHex = CStr(x)
        End If
    End Function

    ' función que codifica el dato
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    Private Function Encriptar(ByVal DataValue As Object) As Object

        Dim x As Long
        Dim Temp As String
        Dim TempNum As Integer
        Dim TempChar As String
        Dim TempChar2 As String

        For x = 1 To Len(DataValue)
            TempChar2 = Mid(DataValue, x, 1)
            TempNum = Int(Asc(TempChar2) / 16)
            If ((TempNum * 16) < Asc(TempChar2)) Then
                TempChar = ConvToHex(Asc(TempChar2) - (TempNum * 16))
                Temp = Temp & ConvToHex(TempNum) & TempChar
            Else
                Temp = Temp & ConvToHex(TempNum) & "0"
            End If
        Next x

        Encriptar = Temp
    End Function

    Private Function ConvToInt(ByVal x As String) As Integer

        Dim x1 As String
        Dim x2 As String
        Dim Temp As Integer

        x1 = Mid(x, 1, 1)
        x2 = Mid(x, 2, 1)

        If IsNumeric(x1) Then
            Temp = 16 * Int(x1)
        Else
            Temp = (Asc(x1) - 55) * 16
        End If

        If IsNumeric(x2) Then
            Temp = Temp + Int(x2)
        Else
            Temp = Temp + (Asc(x2) - 55)
        End If
        ConvToInt = Temp
    End Function

    ' función que decodifica el dato
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    Private Function Desencriptar(ByVal DataValue As Object) As Object
        On Error Resume Next
        Dim x As Long
        Dim Temp As String
        Dim HexByte As String
        For x = 1 To Len(DataValue) Step 2

            HexByte = Mid(DataValue, x, 2)
            Temp = Temp & Chr(ConvToInt(HexByte))

        Next x
        Desencriptar = Temp
    End Function

    Public Function EncryptString(ByVal Cadena As String, ByVal Llave As String) As String
        Dim AuxEnc
        Key = Llave
        AuxEnc = Crypt(Cadena)
        EncryptString = Encriptar(AuxEnc)
    End Function

    Public Function DecryptString(ByVal Cadena As String, ByVal Llave As String) As String
        Dim AuxDec
        Key = Llave
        AuxDec = Desencriptar(Cadena)
        DecryptString = Decrypt(AuxDec)
    End Function
End Class
