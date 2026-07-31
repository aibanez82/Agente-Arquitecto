<?php
            /*

              //Create RC4 Object
             	$rc4crypt = new rc4();

             //To ENCRYPT
                $string = "hola";
                $encryptedstring = $rc4crypt->StringToHexString($rc4crypt->Salaa($string,'SEMILLA'));
             //To DECRYPT
                $encryptedstring = "ABCDEF123456789ABCDEF";
                $string = $rc4crypt->Salaa($rc4crypt->HexStringToString($HTTP_POST_VARS[respuesta]),'SEMILLA');
            */

            class rc4{

                           var $sTempUN = "";
                           var $sTempPW = "";
                           var $sbox = array();
                           var $KEY = array();
                           var $sUser = "";
                           var $sPassw = "";


                           function RC4Initialize($strPwd){
                                               $tempSwap = 0;
                                               $i = 0;
                                               $b = 0;
                                               $intLength = 0;

                                               $intLength = strlen($strPwd);

                                               for($i = 0; $i <= 255; $i++){ // For a = 0 To 255
                                                           $this->KEY[$i] = ord(substr($strPwd,$i%$intLength,1));
                                                           $this->sbox[$i] = $i;
                                               }

                                               $b = 0;
                                               for($i = 0; $i <= 255; $i++){ // For a = 0 To 255
                                                           $b = ($b + $this->sbox[$i] + $this->KEY[$i])%256;
                                                           $tempSwap = $this->sbox[$i];
                                                           $this->sbox[$i] = $this->sbox[$b];
                                                           $this->sbox[$b] = $tempSwap;
                                               }
                           }



                           function Salaa($plaintxt, $key){
                                                $this->RC4Initialize($key);
                                               $temp = 0;
                                               $a = 0;
                                               $i = 0;
                                               $j = 0;
                                               $k;
                                               $cipherby = 0;
                                               $cipher = "";

                                               for($a = 0; $a < strlen($plaintxt); $a++){
                                                           $i = ($i + 1)%256;
                                                           $j = ($j + $this->sbox[$i])%256;
                                                           $temp = $this->sbox[$i];
                                                           $this->sbox[$i] = $this->sbox[$j];
                                                           $this->sbox[$j] = $temp;

                                                           $k = $this->sbox[($this->sbox[$i] + $this->sbox[$j])%256];

                                                           $cipherby = ord(substr($plaintxt,$a,1)) ^ $k;
                                                           $cipher = $cipher.chr($cipherby);
                                               }

                                               return $cipher;
                           }


                           function StringToHexString($b){
                                               $sb="";
                                               for($i = 0; $i < strlen($b); $i++){
                                                           $tmpb = $b;
                                                           $v = ord(substr($tmpb,$i,1)) & 0xFF;
                                                           //print("V:".$v."<br>");
                                                           if($v < 16){
                                                                       $sb = $sb.'0';
                                                           }
                                                           $sb = $sb.dechex($v);
                                                           //print("<br>V:".$v);
                                                           //print("<br>tmp:".substr($tmpb,$i,1));
                                                           //print("<br>SB:".dechex($v));
                                               }
                                               return $sb;
                           }

                           // DES-ENCRIPTADO

                           function HexStringToString($s){
                                    $Result = "";
                                   $len = strlen($s)/2;
                                   for($i=0; $i < $len; $i++){
                                               $index = $i * 2;
                                               //print("<br>v".intval(substr($s,$index,2),16));
                                               $v = intval(substr($s,$index,2),16);
                                               $Result = $Result.chr($v);
                                   }
                                   return $Result;
                           }



                           function Avain(){

                           }
            }
?>