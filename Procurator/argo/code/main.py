import os
import subprocess

timeoutSecs = 86400

logDir = "./log"

buildtranslatorBinPath = "Translator/build/p4c-translator"

def makeLogDir(logDir):
    if not os.path.isdir(logDir):
        os.makedirs(logDir)
    print(f"---- Logs directory at {os.path.abspath(logDir)}. ----")

# SpecFile: regWrite + CPI
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

    # def runTool(cmd, prefix="boogie"):
    #     print(f"{cmd}")
    #     try:
    #         outProcess = subprocess.run(cmd, timeout=timeoutSecs, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    #         strout = outProcess.stdout.decode()
    #     except subprocess.TimeoutExpired as e:
    #         # print(f"Cannot open subprocess: {e}")
    #         strout = f"==== TIMEOUT for {timeoutSecs} seconds ====\n" +  e.stdout.decode()
    #         print("Timeout.")
    #     # endtry
    #     checkLogPath = os.path.join(testLogDir, f"log_{prefix}_check_{p4FileName}.txt")
    #     with open(checkLogPath, "w") as f:
    #         f.write(strout)
    #     print(f"==== {prefix} check log at {os.path.abspath(checkLogPath)}. ====")

    # Solely use boogie can be think as stateless verification
    # Boogie test file
    # boogieOutPath = "p4Inv_boogie.bpl"
    # boogieOutPath = os.path.join(testLogDir, boogieOutPath)
    # genTranslateOutput(boogieOutPath, prefix="boogie")

    # # run Boogie   
    # # boogieCheckCmd = f"time mono Boogie/Binaries/Boogie.exe -trace -nologo -noinfer -contractInfer {boogieOutPath}"
    # boogieCheckCmd = f"time {boogieBinPath} -trace -proverOpt:PROVER_PATH={z3Path} -contractInfer {boogieOutPath}"
    # runTool(boogieCheckCmd)

    # Sorcar test file -- stateful verification
    sorcarOutPath = f"{switch_id}.pml"
    sorcarOutPath = os.path.join(testLogDir, sorcarOutPath)
    genTranslateOutput(sorcarOutPath, prefix="p4Inv", simpleConjecture=False)

    # sorcarCheckCmd = f"time {boogieBinPath} -trace -contractInfer -useProverEvaluate -mv:z3model -proverOpt:PROVER_PATH={z3Path} -mlHoudini:{sorcarBinPath} -learnerOptions:\"-a sorcar\" {sorcarOutPath}"

    # runTool(sorcarCheckCmd, "p4Inv")

    # clean mid files
    cleanCmd = f"rm -f log.txt; cd {testLogDir}; rm -rf *.attributes *.data *.horn *.intervals *.status *.R *.statistics *.bound log.txt"
    if clean:
        print(cleanCmd)
        outProcess = subprocess.run(cleanCmd, timeout=timeoutSecs, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        print("Clean Done.")

if __name__ == "__main__":
    # parser = argparse.ArgumentParser(description="P4Inv")
    # parser.add_argument("--p4", type=str, help="The p4 file to be checked.", required=True)
    # parser.add_argument("--switchID", type=str, help="The name to distinguish switches.", required=True)
    # parser.add_argument("--init", type=str, help="The register initialization file. Deafult is dummy.p4inv (no initialization).",
    # default="dummy.p4inv")
    # args = parser.parse_args()
    # testP4Inv(args.p4, args.init)

    # Or, u can run p4inv locally
    # testP4Inv("dataset/P4NIS/P4NIS.p4", "dataset/P4NIS/init.p4inv")
    # testP4Inv("dataset/P4xos/acceptor.p4", "dataset/P4xos/acceptor.p4inv", "s1")
    # testP4Inv("dataset/P4xos/learner.p4", "dataset/P4xos/learner.p4inv", "s2")
    # testP4Inv("dataset/FRR/main.p4", "dataset/FRR/init.p4inv")
    # testP4Inv("dataset/Blink/main.p4", "dataset/Blink/init.p4inv")


    seperator = ","
    port_mapping_s1 = seperator.join(["ALL:s2"])
    port_mapping_s2 = seperator.join(["ALL:s3"])
    port_mapping_s3 = seperator.join(["ALL:client"])
    testP4Inv("dataset/Netchain/netchain_16.p4", "dataset/Netchain/commands_1.txt", "s1", port_mapping_s1)
    testP4Inv("dataset/Netchain/netchain_16.p4", "dataset/Netchain/commands_2.txt", "s2", port_mapping_s2)
    testP4Inv("dataset/Netchain/netchain_16.p4", "dataset/Netchain/commands_3.txt", "s3", port_mapping_s3)

    # seperator = ","
    # port_mapping_s1 = seperator.join(["1:h1", "2:h2", "3:s3", "4:s4"])
    # port_mapping_s2 = seperator.join(["1:h3", "2:h4", "3:s4", "4:s3"])
    # port_mapping_s3 = seperator.join(["1:s1", "2:s2"])
    # port_mapping_s4 = seperator.join(["1:s2", "2:s1"])

    # testP4Inv("dataset/ipv4/basic.p4", "dataset/ipv4/commands_1.txt", "s1", port_mapping_s1)
    # testP4Inv("dataset/ipv4/basic.p4", "dataset/ipv4/commands_2.txt", "s2", port_mapping_s2)
    # testP4Inv("dataset/ipv4/basic.p4", "dataset/ipv4/commands_3.txt", "s3", port_mapping_s3)
    # testP4Inv("dataset/ipv4/basic.p4", "dataset/ipv4/commands_4.txt", "s4", port_mapping_s4)
