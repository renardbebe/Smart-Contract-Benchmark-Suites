 

pragma solidity ^0.4.15;

 
 
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
    function balanceOf(address who) constant public returns (uint256);
    function issueTokens(address, uint256, DNNSupplyAllocations) public pure returns (bool) {}
}

 
 
contract DNNTradeGame {

   
  DNNToken public dnnToken;

   
  address owner = 0x3Cf26a9FE33C219dB87c2e50572e50803eFb2981;

	 
	 
  event Winner(address indexed to, uint256 dnnBalance, uint256 dnnWon);
  event Trader(address indexed to, uint256 dnnBalance);

   
  modifier onlyOwner() {
      require (msg.sender == owner);
      _;
  }

   
  function pickWinner(address winnerAddress, uint256 dnnToReward, DNNToken.DNNSupplyAllocations allocationType)
    public
    onlyOwner
  {
      uint256 winnerDNNBalance = dnnToken.balanceOf(msg.sender);

      if (!dnnToken.issueTokens(winnerAddress, dnnToReward, allocationType)) {
          revert();
      }
      else {
          emit Winner(winnerAddress, winnerDNNBalance, dnnToReward);
      }
  }

   
  constructor() public
  {
      dnnToken = DNNToken(0x9D9832d1beb29CC949d75D61415FD00279f84Dc2);
  }

	 
	function () public payable {

       
      address dnnHolder = msg.sender;

       
      uint256 dnnHolderBalance = dnnToken.balanceOf(msg.sender);

       
      emit Trader(dnnHolder, dnnHolderBalance);

      if (msg.value > 0) {
          owner.transfer(msg.value);
      }
	}
}