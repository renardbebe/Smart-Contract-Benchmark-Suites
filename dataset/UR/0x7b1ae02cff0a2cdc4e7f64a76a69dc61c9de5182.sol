 

pragma solidity ^0.4.21;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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


contract TraxionWallet is Ownable {
    using SafeMath for uint;

    constructor(){
        transferOwnership(0xdf4CF47303a3607732f9bF193771F54Bb288a2dF);
    }

     
    address public wallet = 0xbee44A7b93509270dbe90000f7ff31268D8F075e;

     
    uint public weiPerToken = 0.0007 ether;

     
    uint public decimals = 18;

     
    uint public minInvestment = 1.0 ether;

     
    uint public investmentUpperBounds = 2000 ether;

     
    uint public hardcap = 45000 ether;

     
    uint public weiRaised = 0;

    event TokenPurchase(address indexed beneficiary, uint value, uint amount);

     
    mapping (address => bool) public whitelistedAddr;
    mapping (address => uint) public totalInvestment;

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function whitelistAddress(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = true;
        }
    }

     
    function blacklistAddr(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = false;
        }
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint tokens = _getTokenAmount(weiAmount);

        assert(tokens != 0);

         
        weiRaised = weiRaised.add(weiAmount);

        emit TokenPurchase(msg.sender, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);

        require(_weiAmount >= minInvestment);
        require(whitelistedAddr[_beneficiary]);
        require(totalInvestment[_beneficiary].add(_weiAmount) <= investmentUpperBounds);
        require(weiRaised.add(_weiAmount) <= hardcap);
    }


     
    function _updatePurchasingState(address _beneficiary, uint _weiAmount) internal {
        totalInvestment[_beneficiary] = totalInvestment[_beneficiary].add(_weiAmount);
    }

     
    function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
        return _weiAmount.mul(10 ** decimals).div(weiPerToken);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}