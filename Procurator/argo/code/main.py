import os
import subprocess

timeoutSecs = 86400

logDir = "./log"

buildtranslatorBinPath = "Translator/build/p4c-translator"

def makeLogDir(logDir):
    if not os.path.isdir(logDir):
        os.makedirs(logDir)
    print(f"---- Logs directory at {os.path.abspath(logDir)}. ----")


def testP4Inv(p4File, specFile, switch_id, port_mapping, translateOutputPath=".", clean=True):
    if not os.path.isfile(p4File):
        print(f"Error: File {p4File} does not exist.")
        return

    if not os.path.isfile(specFile):
        print(f"Error: File {specFile} does not exist.")
        return

    # get the basename of the data directory
    dataDirName = os.path.basename(os.path.dirname(p4File))
    testLogDir = os.path.join(logDir, dataDirName)
    makeLogDir(testLogDir)
    
    p4FileName, _ = os.path.splitext(os.path.basename(p4File))
    
    def genTranslateOutput(file_name, prefix="boogie", simpleConjecture=False):
        outputPath = os.path.join(translateOutputPath, file_name)
        translateCmd = f"./{buildtranslatorBinPath} {p4File} --switchID {switch_id} --port_dst {port_mapping} --bmv2cmds {specFile} -o {outputPath} {'--simpleConjecture' if simpleConjecture else ''}"
        print(f"{translateCmd}")
        outProcess = subprocess.run(translateCmd, timeout=timeoutSecs, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        strout = outProcess.stdout.decode('gbk')
        translateLogPath = os.path.join(testLogDir, f"log_translate_{prefix}_{p4FileName}_{switch_id}.txt")
        with open(translateLogPath, "w") as f:
            f.write(strout)
            print(f"==== Translate log at {os.path.abspath(testLogDir)}. ====")
        outProcess.check_returncode()   # if return code non-zero, abort

    sorcarOutPath = f"{switch_id}.pml"
    sorcarOutPath = os.path.join(testLogDir, sorcarOutPath)
    genTranslateOutput(sorcarOutPath, prefix="p4Inv", simpleConjecture=False)

    cleanCmd = f"rm -f log.txt; cd {testLogDir}; rm -rf *.attributes *.data *.horn *.intervals *.status *.R *.statistics *.bound log.txt"
    if clean:
        print(cleanCmd)
        outProcess = subprocess.run(cleanCmd, timeout=timeoutSecs, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        print("Clean Done.")

if __name__ == "__main__":
    seperator = ","
    port_mapping_s1 = seperator.join(["ALL:s2"])
    port_mapping_s2 = seperator.join(["ALL:s3"])
    port_mapping_s3 = seperator.join(["ALL:client"])
    testP4Inv("dataset/Netchain/netchain_16.p4", "dataset/Netchain/commands_1.txt", "s1", port_mapping_s1)
    testP4Inv("dataset/Netchain/netchain_16.p4", "dataset/Netchain/commands_2.txt", "s2", port_mapping_s2)
    testP4Inv("dataset/Netchain/netchain_16.p4", "dataset/Netchain/commands_3.txt", "s3", port_mapping_s3)
