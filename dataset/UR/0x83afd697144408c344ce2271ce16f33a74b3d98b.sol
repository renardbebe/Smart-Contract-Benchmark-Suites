 
contract NOCUSTCommitChain is
    BimodalProxy,
    DepositProxy,
    WithdrawalProxy,
    ChallengeProxy,
    RecoveryProxy
{
    using SafeMathLib256 for uint256;

     
    constructor(uint256 blocksPerEon, address operator)
        public
        BimodalProxy(blocksPerEon, operator)
    {
         
        ledger.trailToToken.push(address(this));
        ledger.tokenToTrail[address(this)] = 0;
    }

     
    function registerERC20(ERC20 token) public onlyOperator() {
        require(ledger.tokenToTrail[token] == 0);
        ledger.tokenToTrail[token] = uint64(ledger.trailToToken.length);
        ledger.trailToToken.push(token);
    }

     
    function submitCheckpoint(bytes32 accumulator, bytes32 merkleRoot)
        public
        onlyOperator()
        onlyWhenContractUnpunished()
    {
        uint256 eon = ledger.currentEon();
        require(
            ledger.parentChainAccumulator[eon.sub(1).mod(ledger.EONS_KEPT)] ==
                accumulator,
            "b"
        );
        require(ledger.getLiveChallenges(eon.sub(1)) == 0, "c");
        require(eon > ledger.lastSubmissionEon, "d");

        ledger.lastSubmissionEon = eon;

        BimodalLib.Checkpoint storage checkpoint = ledger.getOrCreateCheckpoint(
            eon,
            eon
        );
        checkpoint.merkleRoot = merkleRoot;

        emit CheckpointSubmission(eon, merkleRoot);
    }
}
