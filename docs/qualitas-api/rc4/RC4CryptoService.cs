using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace cotiza_seguros.Services.Qualitas
{
    public class RC4CryptoService
    {
        #region Constructor
        /// <summary>
        /// Sin constructor de parámetros
        /// </summary>
        public RC4CryptoService()
        {
            this.Key = "KEY_MERCHANT";
            this.encoding = Encoding.Default;
            this.encoderMode = EncoderMode.HexEncoder; //EncoderMode.Base64Encoder;;
        }
        #endregion

        #region atributo
        /// <summary>
        /// llave
        /// </summary>
        public string Key { get; set; }
        /// <summary>
        /// codificación
        /// </summary>
        public Encoding encoding { get; set; }
        /// <summary>
        /// modo de codificación
        /// </summary>
        public EncoderMode encoderMode { get; set; }
        /// <summary>
        /// Método de instancia
        /// </summary>
        public static RC4CryptoService RC4 { get { return new RC4CryptoService(); } }
        #endregion

        #region medoso
        /// <summary>
        /// modo de codificación
        /// </summary>
        public enum EncoderMode
        {
            /// <summary>
            /// modo Base64
            /// </summary>
            Base64Encoder,
            /// <summary>
            /// modo hexadecimal
            /// </summary>
            HexEncoder
        }
        /// <summary>
        /// cifrado
        /// </summary>
        /// <param name = "data"> texto sin formato </param>
        /// <returns></returns>
        public String Encrypt(String data)
        {
            return this.Encrypt(data, this.Key, this.encoderMode);
        }
        /// <summary>
        /// Cifrado de cadenas con modo de codificación
        /// </summary>
        /// <param name = "data"> Datos a cifrar </param>
        /// <param name = "key"> contraseña </param>
        /// <param name = "em"> Modo de codificación </param>
        /// <returns> cadena codificada encriptada </returns>
        public String Encrypt(String data, String key, EncoderMode em )
        {
            if (string.IsNullOrEmpty(data)) return "";
            if (string.IsNullOrEmpty(key)) key = this.Key;
            if (em == EncoderMode.Base64Encoder)
                return Convert.ToBase64String(this.Encrypt(data.GetBytes(this.encoding), key));
            else
                return this.ByteToHex(this.Encrypt(data.GetBytes(this.encoding), key));
        }
        /// <summary>
        /// descifrar
        /// </summary>
        /// <param name = "data"> texto cifrado </param>
        /// <returns></returns>
        public String Decrypt(String data)
        {
            return this.Decrypt(data, this.Key, this.encoderMode);
        }
        /// <summary>
        /// Descifrado de cadenas con modo de codificación
        /// </summary>
        /// <param name = "data"> Datos a descifrar </param>
        /// <param name = "key"> contraseña </param>
        /// <param name = "em"> Modo de codificación </param>
        /// <retornos> texto plano </returnos>
        public String Decrypt(String data, String key, EncoderMode em)
        {
            if (string.IsNullOrEmpty(data)) return "";
            if (string.IsNullOrEmpty(key)) key = this.Key;
            if (em == EncoderMode.Base64Encoder)
                return this.encoding.GetString(this.Decrypt(Convert.FromBase64String(data), key));
            else
                return this.encoding.GetString(this.Decrypt(this.HexToByte(data), key));
        }
        /// <summary>
        /// cifrado
        /// </summary>
        /// <param name = "data"> Datos a cifrar </param>
        /// <param name = "key"> contraseña </param>
        /// <returns> cadena cifrada con codificación predeterminada </returns>
        public String Encrypt(String data, String key)
        {
            return this.Encrypt(data, key, this.encoderMode);
        }
        /// <summary>
        /// descifrar
        /// </summary>
        /// <param name = "data"> datos codificados para descifrar </param>
        /// <param name = "key"> contraseña </param>
        /// <retornos> texto plano </returnos>
        public String Decrypt(String data, String key)
        {
            return this.Decrypt(data, key, this.encoderMode);
        }
        /// <summary>
        /// Byte de conversión hexadecimal
        /// </summary>
        /// <param name = "hex"> cadena </param>
        /// <returns></returns>
        private Byte[] HexToByte(String hex)
        {
            Int32 iLen = hex.Length;
            if (iLen <= 0 || 0 != iLen % 2)
            {
                return null;
            }
            Int32 dwCount = iLen / 2;
            UInt32 tmp1, tmp2;
            Byte[] pbBuffer = new Byte[dwCount];
            for (Int32 i = 0; i < dwCount; i++)
            {
                tmp1 = (UInt32)hex[i * 2] - (((UInt32)hex[i * 2] >= (UInt32)'A') ? (UInt32)'A' - 10 : (UInt32)'0');
                if (tmp1 >= 16) return null;
                tmp2 = (UInt32)hex[i * 2 + 1] - (((UInt32)hex[i * 2 + 1] >= (UInt32)'A') ? (UInt32)'A' - 10 : (UInt32)'0');
                if (tmp2 >= 16) return null;
                pbBuffer[i] = (Byte)(tmp1 * 16 + tmp2);
            }
            return pbBuffer;
        }
        /// <summary>
        /// Byte de conversión hexadecimal
        /// </summary>
        /// <param name = "bytes"> byte </param>
        /// <returns></returns>
        private String ByteToHex(Byte[] bytes)
        {
            if (bytes == null || bytes.Length < 1) return null;
            StringBuilder sbr = new StringBuilder(bytes.Length * 2);
            for (int i = 0; i < bytes.Length; i++)
            {
                if ((UInt32)bytes[i] < 0) return null;
                UInt32 k = (UInt32)bytes[i] / 16;
                sbr.Append((Char)(k + ((k > 9) ? 'A' - 10 : '0')));
                k = (UInt32)bytes[i] % 16;
                sbr.Append((Char)(k + ((k > 9) ? 'A' - 10 : '0')));
            }
            return sbr.ToString();
        }
        /// <summary>
        /// Bytes encriptados
        /// </summary>
        /// <param name = "data"> Palabra de sección </param>
        /// <param name="key">key</param>
        /// <returns></returns>
        private Byte[] Encrypt(Byte[] data, string key)
        {
            if (data == null || key == null) return null;
            Byte[] output = new Byte[data.Length];
            Int64 i = 0;
            Int64 j = 0;
            Byte[] mBox = GetKey(key.GetBytes(this.encoding), 256);
            for (Int64 offset = 0; offset < data.Length; offset++)
            {
                i = (i + 1) % mBox.Length;
                j = (j + mBox[i]) % mBox.Length;
                Byte temp = mBox[i];
                mBox[i] = mBox[j];
                mBox[j] = temp;
                Byte a = data[offset];
                Byte b = mBox[(mBox[i] + mBox[j]) % mBox.Length];
                output[offset] = (Byte)((Int32)a ^ (Int32)b);
            }
            return output;
        }
        /// <summary>
        /// descifrar el byte
        /// </summary>
        /// <param name = "data"> byte </param>
        /// <param name="key">key</param>
        /// <returns></returns>
        private Byte[] Decrypt(Byte[] data, String key)
        {
            return Encrypt(data, key);
        }
        /// <summary>
        /// Rompe la contraseña
        /// </summary>
        /// <param name = "pass"> contraseña </param>
        /// <param name = "kLen"> Longitud de la caja de seguridad </param>
        /// <returns> contraseña interrumpida </returns>
        private Byte[] GetKey(Byte[] pass, Int32 kLen)
        {
            Byte[] mBox = new Byte[kLen];

            for (Int64 i = 0; i < kLen; i++)
            {
                mBox[i] = (Byte)i;
            }
            Int64 j = 0;
            for (Int64 i = 0; i < kLen; i++)
            {
                j = (j + mBox[i] + pass[i % pass.Length]) % kLen;
                Byte temp = mBox[i];
                mBox[i] = mBox[j];
                mBox[j] = temp;
            }
            return mBox;
        }
        #endregion

    }

    /// <summary>
    /// Método de extensión Rc4
    /// </summary>
    public static class Rc4Extend
    {

        /// <summary>
        /// Cadena a flujo de datos
        /// </summary>
        /// <param name="str"></param>
        /// <param name="en"></param>
        /// <returns></returns>
        public static byte[] GetBytes(this string str, Encoding en)
        {

            return en.GetBytes(str);
        }
    }
}