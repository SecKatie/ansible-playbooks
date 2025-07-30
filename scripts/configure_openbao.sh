# SERVICE is the name of the OpenBao service in kubernetes.
# It does not have to match the actual running service, though it may help for consistency.
export SERVICE=openbao

# NAMESPACE where the OpenBao service is running.
export NAMESPACE=vault

# SECRET_NAME to create in the kubernetes secrets store.
export SECRET_NAME=openbao-server-tls

# TMPDIR is a temporary working directory.
export TMPDIR=/tmp

# CSR_NAME will be the name of our certificate signing request as seen by kubernetes.
export CSR_NAME=openbao-csr

openssl genrsa -out ${TMPDIR}/openbao.key 2048

cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${SERVICE}
DNS.2 = *.${SERVICE}.${NAMESPACE}
DNS.3 = *.${SERVICE}.${NAMESPACE}.svc
DNS.4 = *.${SERVICE}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

openssl req -new \
            -key ${TMPDIR}/openbao.key \
            -subj "/CN=system:node:${SERVICE}.${NAMESPACE}.svc;/O=system:nodes" \
            -out ${TMPDIR}/server.csr \
            -config ${TMPDIR}/csr.conf

cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  signerName: kubernetes.io/kubelet-serving
  groups:
  - system:authenticated
  request: $(base64 ${TMPDIR}/server.csr | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create -f ${TMPDIR}/csr.yaml

kubectl certificate approve ${CSR_NAME}

kubectl get csr ${CSR_NAME}

serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/openbao.crt

kubectl config view --raw --minify --flatten \
  -o jsonpath='{.clusters[].cluster.certificate-authority-data}' \
  | base64 --decode > ${TMPDIR}/openbao.ca

kubectl create secret generic ${SECRET_NAME} \
    --namespace ${NAMESPACE} \
    --from-file=openbao.key=${TMPDIR}/openbao.key \
    --from-file=openbao.crt=${TMPDIR}/openbao.crt \
    --from-file=openbao.ca=${TMPDIR}/openbao.ca
