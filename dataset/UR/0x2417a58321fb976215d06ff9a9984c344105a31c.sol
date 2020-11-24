 

pragma solidity 0.4.25;
 
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
    require(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner , "Unauthorized Access");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
interface ERC20Interface {
   
       
     
    function balanceOf(address _owner) view external returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
    function approve(address _spender, uint256 _value) external returns (bool success);
    function disApprove(address _spender)  external returns (bool success);
   function increaseApproval(address _spender, uint _addedValue) external returns (bool success);
   function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool success);
      
     
     
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);
     function name() external view returns (string _name);

     
    function symbol() external view returns (string _symbol);

     
    function decimals() external view returns (uint8 _decimals); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library SafeERC20{

  function safeTransfer(ERC20Interface token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }    
    
  

  function safeTransferFrom(ERC20Interface token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20Interface token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract TansalICOTokenVault is owned{
    
     using SafeERC20 for ERC20Interface;
     ERC20Interface TansalCoin;
      struct Investor {
        string fName;
        string lName;
        uint256 totalTokenWithdrawn;
        bool exists;
    }
    
    mapping (address => Investor) public investors;
    address[] public investorAccts;
    uint256 public numberOFApprovedInvestorAccounts;

     constructor() public
     {
         
         TansalCoin = ERC20Interface(0x0EF0183E9Db9069a7207543db99a4Ec4d06f11cB);
     }
    
     function() public {
          
          revert();
    }
    
     function sendApprovedTokensToInvestor(address _benificiary,uint256 _approvedamount,string _fName, string _lName) public onlyOwner
    {
        uint256 totalwithdrawnamount;
        require(TansalCoin.balanceOf(address(this)) > _approvedamount);
        if(investors[_benificiary].exists)
        {
            uint256 alreadywithdrawn = investors[_benificiary].totalTokenWithdrawn;
            totalwithdrawnamount = alreadywithdrawn + _approvedamount;
            
        }
        else
        {
          totalwithdrawnamount = _approvedamount;
          investorAccts.push(_benificiary) -1;
        }
         investors[_benificiary] = Investor({
                                            fName: _fName,
                                            lName: _lName,
                                            totalTokenWithdrawn: totalwithdrawnamount,
                                            exists: true
            
        });
        numberOFApprovedInvestorAccounts = investorAccts.length;
        TansalCoin.safeTransfer(_benificiary , _approvedamount);
    }
    
     function onlyPayForFuel() public payable onlyOwner{
         
        
    }
    function withdrawEtherFromcontract(uint _amountInwei) public onlyOwner{
        require(address(this).balance > _amountInwei);
      require(msg.sender == owner);
      owner.transfer(_amountInwei);
     
    }
    function withdrawTokenFromcontract(ERC20Interface _token, uint256 _tamount) public onlyOwner{
        require(_token.balanceOf(address(this)) > _tamount);
         _token.safeTransfer(owner, _tamount);
     
    }
}