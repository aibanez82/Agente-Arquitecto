package comun;

public class rc4 //extends Applet
{
   String sTempUN = "";
   String sTempPW = "";
   int sbox[] = new int[256];
   int KEY[] = new int[256];
   String sUser = "";
   String sPassw = "";

   public void RC4Initialize(String strPwd)
   {
      int tempSwap = 0;
      int i = 0;
      int b = 0;
      int intLength = 0;

      intLength = strPwd.length();
      for(i = 0; i <= 255; i++) // For a = 0 To 255
      {
         KEY[i] = (int)(strPwd.charAt(i%intLength));
         sbox[i] = i;
      }

      b = 0;
      for(i = 0; i <= 255; i++) // For a = 0 To 255
      {
         b = (b + sbox[i] + KEY[i])%256;
         tempSwap = sbox[i];
         sbox[i] = sbox[b];
         sbox[b] = tempSwap;
      }
   }


   public String Salaa(String plaintxt, String key)
   {
      RC4Initialize(key);
      int temp = 0;
      int a = 0;
      int i = 0;
      int j = 0;
      int k;
      int cipherby = 0;
      String cipher = "";
      //psw = "&h01 &h23 &h45 &h67 &h89 &hab &hcd &hef"; //kiinteä avain
      //RC4Initialize(psw);

      for(a = 0; a < plaintxt.length(); a++)
      {
         i = (i + 1) % 256;
         j = (j + sbox[i])%256;
         temp = sbox[i];
         sbox[i] = sbox[j];
         sbox[j] = temp;

         k = sbox[(sbox[i] + sbox[j])%256];

         cipherby = ((int)(plaintxt.charAt(a))) ^ k;
         cipher += (char)cipherby;
      }
      return cipher;
   }
   public String Pura(String plaintxt, String key)
   {
      RC4Initialize(key);
      int temp = 0;
      int a = 0;
      int i = 0;
      int j = 0;
      int k;
      int cipherby = 0;
      String cipher = "";

      for(a = 0; a < plaintxt.length(); a++)
      {
         i = (i + 1) % 256;
         j = (j + sbox[i])%256;
         temp = sbox[i];
         sbox[i] = sbox[j];
         sbox[j] = temp;

         k = sbox[(sbox[i] + sbox[j])%256];

         cipherby = ((int)(plaintxt.charAt(a))) ^ k;
         cipher += (char)cipherby;
      }
      return cipher;
   }

   public String Avain()
   {
      // Testaaminen
      String Avain = "";
      for(int i = 0; i <= 255; i++) // For a = 0 To 255
      {
         Avain += (char)KEY[i];
      }
      return Avain;
   }
	public String hexStringToString(String s) {
		String Result = "";
		byte[] b = new byte[s.length() / 2];
		for (int i = 0; i < b.length; i++){
		  int index = i * 2;
		  int v = Integer.parseInt(s.substring(index, index + 2), 16);
		  Result += (char)v;
		}
		return Result;
	  }

	public String StringToHexString(String b){
		StringBuffer sb = new StringBuffer(b.length() * 2);
		for (int i = 0; i < b.length(); i++){
		  int v = b.charAt(i)  & 0xff;
		  if (v < 16) {
			sb.append('0');
		  }
		  sb.append(Integer.toHexString(v));
		}
		return sb.toString().toUpperCase();
	}
}
