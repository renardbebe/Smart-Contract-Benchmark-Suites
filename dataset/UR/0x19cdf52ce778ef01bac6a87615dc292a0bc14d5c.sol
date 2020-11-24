 

pragma solidity 0.4.24;
pragma experimental "v0.5.0";

library SafeMath {

   
   
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

interface RTCoinInterface {
    

     
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function transferFrom(address _owner, address _recipient, uint256 _amount) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool approved);

     
    function totalSupply() external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

     
    function mint(address _recipient, uint256 _amount) external returns (bool);

    function stakeContractAddress() external view returns (address);

    function mergedMinerValidatorAddress() external view returns (address);
    
     
    function freezeTransfers() external returns (bool);

    function thawTransfers() external returns (bool);
}

 
 
 
 
contract MergedMinerValidator {

    using SafeMath for uint256;
    
     
    uint256 constant public SUBMISSIONREWARD = 500000000000000000;
     
    uint256 constant public BLOCKREWARD = 300000000000000000;
    string  constant public VERSION = "production";
    address constant public TOKENADDRESS = 0xecc043b92834c1ebDE65F2181B59597a6588D616;
    RTCoinInterface constant public RTI = RTCoinInterface(TOKENADDRESS);
    
    address public tokenAddress;
    address public admin;
    uint256 public lastBlockSet;

    enum BlockStateEnum { nil, submitted, claimed }

    struct Blocks {
        uint256 number;
        address coinbase;
        BlockStateEnum state;
    }

    mapping (uint256 => Blocks) public blocks;
    mapping (uint256 => bytes) public hashedBlocks;
    event BlockInformationSubmitted(address indexed _coinbase, uint256 indexed _blockNumber, address _submitter);
    event MergedMinedRewardClaimed(address indexed _claimer, uint256[] indexed _blockNumbers, uint256 _totalReward);

    modifier submittedBlock(uint256 _blockNum) {
        require(blocks[_blockNum].state == BlockStateEnum.submitted, "block state must be submitted");
        _;

    }

    modifier nonSubmittedBlock(uint256 _blockNum) {
        require(blocks[_blockNum].state == BlockStateEnum.nil, "block state must be empty");
        _;
    }

    modifier isCoinbase(uint256 _blockNumber) {
        require(msg.sender == blocks[_blockNumber].coinbase, "sender must be coinbase");
        _;
    }

    modifier canMint() {
        require(RTI.mergedMinerValidatorAddress() == address(this), "merged miner contract on rtc token must be set to this contract");
        _;
    }

    modifier notCurrentSetBlock(uint256 _blockNumber) {
        require(_blockNumber > lastBlockSet, "unable to submit information for already submitted block");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only an admin can invoke this function");
        _;
    }

    modifier tokenAddressNotSet() {
        require(tokenAddress == address(0), "token address must not be set");
        _;
    }

    constructor(address _admin) public {
        admin = _admin;
        Blocks memory b = Blocks({
            number: block.number,
            coinbase: block.coinbase,
            state: BlockStateEnum.submitted
        });
        lastBlockSet = block.number;
        blocks[block.number] = b;
         
        emit BlockInformationSubmitted(block.coinbase, block.number, address(0));
    }

     
    function submitBlock() public nonSubmittedBlock(block.number) notCurrentSetBlock(block.number) returns (bool) {
        Blocks memory b = Blocks({
            number: block.number,
            coinbase: block.coinbase,
            state: BlockStateEnum.submitted
        });
        lastBlockSet = block.number;
        blocks[block.number] = b;
         
        emit BlockInformationSubmitted(block.coinbase, block.number, msg.sender);
        require(RTI.mint(msg.sender, SUBMISSIONREWARD), "failed to transfer reward to block submitter");
        return true;
    }
    

     
    function claimReward(uint256 _blockNumber) 
        internal
        isCoinbase(_blockNumber) 
        submittedBlock(_blockNumber)
        returns (uint256) 
    {
         
        blocks[_blockNumber].state = BlockStateEnum.claimed;
        return BLOCKREWARD;
    }

     
    function bulkClaimReward(uint256[] _blockNumbers) external canMint returns (bool) {
        require(_blockNumbers.length <= 20, "can only claim up to 20 rewards at once");
        uint256 totalMint;
        for (uint256 i = 0; i < _blockNumbers.length; i++) {
             
            totalMint = totalMint.add(claimReward(_blockNumbers[i]));
        }
        emit MergedMinedRewardClaimed(msg.sender, _blockNumbers, totalMint);
         
        require(totalMint > 0, "total coins to mint must be greater than 0");
        require(RTI.mint(msg.sender, totalMint), "unable to mint tokens");
        return true;
    }

     
    function goodNightSweetPrince() public onlyAdmin returns (bool) {
        selfdestruct(msg.sender);
        return true;
    }

}