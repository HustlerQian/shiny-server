#Load methylation matrix
data=read.csv('./GC_1926_methy.csv',header = T)
METHY_MAT=data[,-1]
rownames(METHY_MAT)=data[,1]
colnames(METHY_MAT)=substr(colnames(METHY_MAT),1,12)
#Load expression matrix
data=read.csv('./GC_1926_exp.csv',header = T)
EXP_MAT=log2(data[,-1]+1)
rownames(EXP_MAT)=data[,1]
colnames(EXP_MAT)=substr(colnames(EXP_MAT),1,12)
#Load anotation matrix
ano_mat=read.table('./clinical_patient_GC.txt',header = T,sep = '\t',quote='')
ANO_COL=ano_mat[,c(-1)]
row.names(ANO_COL)=gsub('-','.',ano_mat[,1],fixed = T)
