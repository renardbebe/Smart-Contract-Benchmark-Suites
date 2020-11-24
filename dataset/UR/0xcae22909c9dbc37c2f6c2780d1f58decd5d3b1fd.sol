 

pragma solidity ^0.4.25;



 
library SafeMath256 {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
}


 
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract A004{

  using SafeMath256 for uint256;
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);

function batchTtransferEther(address[] _to,uint256[] _value) public payable {
    require(_to.length>0);
     
    for(uint256 i=0;i<_to.length;i++)
    {
        _to[i].transfer(_value[i]);
    }
}

 
  
   
  
    
}