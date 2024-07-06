# gpg - cheatsheet

**Generate keys**

```bash
GPG_PASSPHRASE="damascus-enthrone4swelter.downpour"
GNUPG_HOME="$(pwd)/test/res/gpghome"
output_file="keygen_output.txt"
mkdir -p "${GNUPG_HOME}"
chmod 700 "${GNUPG_HOME}"
gpg --homedir "${GNUPG_HOME}" --batch --no-tty --status-fd 1 --passphrase "${GPG_PASSPHRASE}" --quick-generate-key "test@sample.domain" "rsa4096" "encrypt" "2090-01-01"  >"${output_file}" 2>&1
fpr="$(awk '/KEY_CREATED P/ { print $4}' "${output_file}")"
echo "Fingerprint: ${fpr}"
#Fingerprint: DBD22393C9BD7B1B5D61BB26E5A1C24B486A5ABC
revocation_cert_path="$(awk '/revocation/ { print substr($6, 2, length($6)-2) }' "${output_file}")"
echo "Revocation certificate path: ${revocation_cert_path}"
#Revocation certificate path: /home/user/src/os/rynkowsg/orbs-rynkowsg/orbs/gpg/test/res/gpghome/openpgp-revocs.d/DBD22393C9BD7B1B5D61BB26E5A1C24B486A5ABC.rev

gpg --homedir "gpghome" -k --keyid-format long
#/home/user/src/os/rynkowsg/orbs-rynkowsg/orbs/gpg/test/res/gpghome/pubring.kbx
#------------------------------------------------------------------------------
#pub   rsa4096/E5A1C24B486A5ABC 2024-07-06 [CE] [expires: 2090-01-01]
#      DBD22393C9BD7B1B5D61BB26E5A1C24B486A5ABC
#uid                 [ultimate] test@sample.domain
```

**Export keys**

```bash
# export to armored files
export_dir="$(pwd)/test/res/gpgexport"
mkdir -p "${export_dir}"
gpg --homedir "${GNUPG_HOME}" --batch --pinentry-mode loopback --armor --export > "${export_dir}/public-${fpr}.asc"
gpg --homedir "${GNUPG_HOME}" --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --armor --export-secret-key "${fpr}" > "${export_dir}/private-${fpr}.asc"

# export to Base64 and save in variables
base64 -w 0 "${export_dir}/public-${fpr}.asc" > "${export_dir}/public-${fpr}.asc.b64"
GPG_PUBLIC_KEY_B64="$(cat "${export_dir}/public-${fpr}.asc.b64")" # later for showing how is decoded on CI
base64 -w 0 "${export_dir}/private-${fpr}.asc" > "${export_dir}/private-${fpr}.asc.b64"
GPG_PRIVATE_KEY_B64="$(cat "${export_dir}/private-${fpr}.asc.b64")" # later for showing how is decoded on CI

# copy to CircleCI
echo "${GPG_PUBLIC_KEY_B64}" | clip-copy # copy to CircleCI to GPG_PUBLIC_KEY_B64
echo "${GPG_PRIVATE_KEY_B64}" | clip-copy # copy to CircleCI to GPG_PRIVATE_KEY_B64
echo "${GPG_PASSPHRASE}" | clip-copy # copy to CircleCI to GPG_PASSPHRASE
```

**Encrypt / Decrypt**

```bash
gpg --homedir "gpghome" --output msg.txt.gpg --encrypt --recipient E5A1C24B486A5ABC --pinentry-mode loopback --passphrase $GPG_PASSPHRASE msg.txt
```

```bash
gpg --homedir "gpghome" --output msg.txt --decrypt --pinentry-mode loopback --passphrase $GPG_PASSPHRASE msg.txt.gpg
# or
gpg --homedir "gpghome" --decrypt --pinentry-mode loopback --passphrase $GPG_PASSPHRASE msg.txt.gpg > msg.txt
```
