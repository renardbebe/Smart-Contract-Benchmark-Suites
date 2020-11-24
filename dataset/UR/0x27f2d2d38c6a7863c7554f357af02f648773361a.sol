 

pragma solidity 0.4.18;

 

 
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

 

 
contract FxRates is Ownable {
    using SafeMath for uint256;

    struct Rate {
        string rate;
        string timestamp;
    }

     
    event RateUpdate(string symbol, uint256 updateNumber, string timestamp, string rate);

    uint256 public numberBtcUpdates = 0;

    mapping(uint256 => Rate) public btcUpdates;

    uint256 public numberEthUpdates = 0;

    mapping(uint256 => Rate) public ethUpdates;

     
    function updateEthRate(string _rate, string _timestamp) public onlyOwner {
        numberEthUpdates = numberEthUpdates.add(1);
        ethUpdates[numberEthUpdates] = Rate({
            rate: _rate,
            timestamp: _timestamp
        });
        RateUpdate("ETH", numberEthUpdates, _timestamp, _rate);
    }

     
    function updateBtcRate(string _rate, string _timestamp) public onlyOwner {
        numberBtcUpdates = numberBtcUpdates.add(1);
        btcUpdates[numberBtcUpdates] = Rate({
            rate: _rate,
            timestamp: _timestamp
        });
        RateUpdate("BTC", numberBtcUpdates, _timestamp, _rate);
    }

     
    function getEthRate() public view returns(Rate) {
         
        return ethUpdates[numberEthUpdates];
             
             
         
    }

     
    function getBtcRate() public view returns(string, string) {
         
        return (
            btcUpdates[numberBtcUpdates].rate,
            btcUpdates[numberBtcUpdates].timestamp
        );
    }

     
    function getHistEthRate(uint256 _updateNumber) public view returns(string, string) {
        require(_updateNumber <= numberEthUpdates);
        return (
            ethUpdates[_updateNumber].rate,
            ethUpdates[_updateNumber].timestamp
        );
    }

     
    function getHistBtcRate(uint256 _updateNumber) public view returns(string, string) {
        require(_updateNumber <= numberBtcUpdates);
        return (
            btcUpdates[_updateNumber].rate,
            btcUpdates[_updateNumber].timestamp
        );
    }
}