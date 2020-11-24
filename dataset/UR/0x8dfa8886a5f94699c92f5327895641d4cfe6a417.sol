 

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;


pragma solidity ^0.4.23;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
contract ERC20 {

     
     

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

     
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

     
     


    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}


contract CuteCoinInterface is ERC20
{
    function mint(address target, uint256 mintedAmount) public;
    function mintBulk(address[] target, uint256[] mintedAmount) external;
    function burn(uint256 amount) external;
}


 
 
contract CuteCoinShop is Pausable
{
    CuteCoinInterface token;

    mapping (address=>bool) operatorAddress;

    function addOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _newOperator) public onlyOwner {
        delete(operatorAddress[_newOperator]);
    }

    function isOperator(address _address) view public returns (bool) {
        return operatorAddress[_address];
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender) || msg.sender == owner);
        _;
    }


    event CuteCoinShopBuy(address sender, uint value, bytes extraData);

    function setToken(CuteCoinInterface _token)
        external
        onlyOwner
    {
        token = _token;
    }

    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData)
        external
        whenNotPaused
    {
        require(_tokenContract == address(token));
        require(token.transferFrom(_sender, address(this), _value));

        emit CuteCoinShopBuy(_sender, _value, _extraData);
    }

     
     
    function withdrawAllTokensFromBalance(ERC20 _tokenContract, address _withdrawToAddress) external onlyOperator
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }

     
     
    function withdrawTokenFromBalance(ERC20 _tokenContract, address _withdrawToAddress, uint amount) external onlyOperator
    {
        _tokenContract.transfer(_withdrawToAddress, amount);
    }
}