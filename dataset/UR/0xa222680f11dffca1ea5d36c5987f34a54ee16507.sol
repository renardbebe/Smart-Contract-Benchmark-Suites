 

pragma solidity 0.5.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


   
  constructor () public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token {
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function allowance(address, address) external view returns (uint);
}

contract Exchange is Ownable {
    using SafeMath for uint;
    
     
    mapping (string => uint) public promoCodes;
    
    uint public fee = 300;
    uint public cxcUnitsPerEth = 100 * 1e18;
    address public cxcTokenAddress = 0xE5E00C5F68bd9922e4Be522b8f18bBD0CaeD0C94;
    
    function setCxcTokenAddress(address _addr) public onlyOwner {
        cxcTokenAddress = _addr;
    }
    
    function setPromoCode(string memory code, uint discountPercentInto100) public onlyOwner {
        promoCodes[code] = discountPercentInto100;
    }
    
    function setFee(uint _fee) public onlyOwner {
        require(_fee < 10000);
        fee = _fee;
    }
    
    function setCxcUnitsPerEth(uint _cxcUnitsPerEth) public onlyOwner {
        cxcUnitsPerEth = _cxcUnitsPerEth;
    }
    
    function getCxcUnitsPerEth_eth_to_cxc() public view returns (uint) {
        return cxcUnitsPerEth.sub(cxcUnitsPerEth.mul(fee).div(1e4));
    }
    
    function getCxcUnitsPerEth_cxc_to_eth() public view returns (uint) {
        return cxcUnitsPerEth.add(cxcUnitsPerEth.mul(fee).div(1e4));
    } 
    
    function () external payable {
         
    }
    
    function withdrawAllEth() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    
    function exchangeCxcToEth(string memory promo) public {
        token tokenReward = token(cxcTokenAddress);
        uint allowance = tokenReward.allowance(msg.sender, address(this));
        require(allowance > 0 && tokenReward.transferFrom(msg.sender, owner, allowance));
        
        uint _cxcUnitsPerEth = getCxcUnitsPerEth_cxc_to_eth();
        uint weiToSend = allowance.mul(1e18).div(_cxcUnitsPerEth);
        if (promoCodes[promo] > 0) {
            weiToSend = weiToSend.add(weiToSend.mul(promoCodes[promo]).div(1e4));
        }
        msg.sender.transfer(weiToSend);
    }
}