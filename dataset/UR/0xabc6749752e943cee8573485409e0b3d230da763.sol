 

pragma solidity 0.4.20;

 

 
contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract PullPayment {
    
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
  
}

 
contract PoWTFInterface {


     

     
    function buy(address _referredBy) public payable returns (uint256);

     
    function reinvest() public;

     
    function exit() public;

     
    function withdraw() public;

     
    function sell(uint256 _amountOfTokens) public;

     
    function transfer(address _toAddress, uint256 _amountOfTokens) public returns (bool);


     

     
    function totalEthereumBalance() public view returns (uint256);

     
    function totalSupply() public view returns (uint256);

     
    function myTokens() public view returns (uint256);

     
    function myDividends(bool _includeReferralBonus) public view returns (uint256);

     
    function balanceOf(address _customerAddress) public view returns (uint256);

     
    function dividendsOf(address _customerAddress) public view returns (uint256);

     
    function sellPrice() public view returns (uint256);

     
    function buyPrice() public view returns (uint256);

     
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256);

     
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256);


     

     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256);

     
    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256);

     
    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256);

     
    function sqrt(uint256 x) internal pure returns (uint256 y);


}

 
contract PoWTFCommunityFund is Ownable, PullPayment {


     

     
    PoWTFInterface public poWtfContract = PoWTFInterface(0x702392282255f8c0993dBBBb148D80D2ef6795b1);


     

    event LogDonateETH(
        address indexed donarAddress,
        uint256 amount,
        uint256 timestamp
    );


     
    
     
    function donateETH() public payable {
         
        poWtfContract.buy.value(msg.value)(msg.sender);
        
         
        LogDonateETH(msg.sender, msg.value, now);
    }

     
    function reinvestDividend() onlyOwner public {
        poWtfContract.reinvest();
    }

     
    function withdrawDividend() onlyOwner public {
        poWtfContract.withdraw();
    }

     
    function assignFundReceiver(address _fundReceiver, uint _amount) onlyOwner public {
         
        require(_amount <= this.balance - totalPayments);

         
        asyncSend(_fundReceiver, _amount);
    }

     
    function() public payable {}

     

    function setPoWtfContract(address _newPoWtfContractAddress) onlyOwner external {
        poWtfContract = PoWTFInterface(_newPoWtfContractAddress);
    }

    
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}