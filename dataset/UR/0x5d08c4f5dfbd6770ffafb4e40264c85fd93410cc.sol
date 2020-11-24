 

pragma solidity ^0.4.11;

 
 
contract DNNToken {
    enum DNNSupplyAllocations {
        EarlyBackerSupplyAllocation,
        PRETDESupplyAllocation,
        TDESupplyAllocation,
        BountySupplyAllocation,
        WriterAccountSupplyAllocation,
        AdvisorySupplyAllocation,
        PlatformSupplyAllocation
    }
    function issueTokens(address, uint256, DNNSupplyAllocations) public returns (bool) {}
}

 
 
contract DNNRedemption {

     
     
     
    DNNToken public dnnToken;

     
     
     
    address public cofounderA;
    address public cofounderB;

     
     
     
    uint256 public tokensDistributed = 0;

     
     
     
    uint256 public maxTokensToDistribute = 30000000 * 1 ether;

     
     
     
    uint256 public seed = 8633926795440059073718754917553891166080514579013872221976080033791214;

     
     
     
    mapping(address => uint256) holders;

     
     
     
    event Redemption(address indexed to, uint256 value);


     
     
     
    modifier onlyCofounders() {
        require (msg.sender == cofounderA || msg.sender == cofounderB);
        _;
    }

     
     
     
     
    function hasDNN(address beneficiary) public view returns (bool) {
        return holders[beneficiary] > 0;
    }

     
     
     
    modifier doesNotHaveDNN(address beneficiary) {
        require(hasDNN(beneficiary) == false);
        _;
    }

     
     
     
     
    function updateMaxTokensToDistribute(uint256 maxTokens)
      public
      onlyCofounders
    {
        maxTokensToDistribute = maxTokens;
    }

     
     
     
     
    function issueTokens(address beneficiary)
        public
        doesNotHaveDNN(beneficiary)
        returns (uint256)
    {
         
        uint256 tokenCount = (uint(keccak256(abi.encodePacked(blockhash(block.number-1), seed ))) % 1000);

         
         
         
         
        if (tokenCount > 200) {
            tokenCount = 200;
        }

         
        tokenCount = tokenCount * 1 ether;

         
        if (tokensDistributed+tokenCount > maxTokensToDistribute) {
            revert();
        }

         
        holders[beneficiary] = tokenCount;

         
        tokensDistributed = tokensDistributed + tokenCount;

         
        DNNToken.DNNSupplyAllocations allocationType = DNNToken.DNNSupplyAllocations.PlatformSupplyAllocation;

         
        if (!dnnToken.issueTokens(beneficiary, tokenCount, allocationType)) {
            revert();
        }

         
        Redemption(beneficiary, tokenCount);

        return tokenCount;
    }

     
     
     
    constructor() public
    {
         
        dnnToken = DNNToken(0x9d9832d1beb29cc949d75d61415fd00279f84dc2);

         
        cofounderA = 0x3Cf26a9FE33C219dB87c2e50572e50803eFb2981;
        cofounderB = 0x9FFE2aD5D76954C7C25be0cEE30795279c4Cab9f;
    }

     
     
     
    function () public payable {
        if (!hasDNN(msg.sender)) issueTokens(msg.sender);
        else revert();
    }
}