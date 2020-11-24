 

pragma solidity ^0.4.24;


interface DelegatedERC20 {
    function allowance(address _owner, address _spender) external view returns (uint256); 
    function transferFrom(address from, address to, uint256 value, address sender) external returns (bool); 
    function approve(address _spender, uint256 _value, address sender) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value, address sender) external returns (bool);
}



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}






 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract TokenFront is ERC20, Ownable {

    string public name = "Test Fox Token";
    string public symbol = "TFT";

    DelegatedERC20 public tokenLogic;
    
    constructor(DelegatedERC20 _tokenLogic, address _owner) public {
        owner = _owner;
        tokenLogic = _tokenLogic; 
    }

    function migrate(DelegatedERC20 newTokenLogic) public onlyOwner {
        tokenLogic = newTokenLogic;
    }

    function allowance(address owner, address spender) 
        public 
        view 
        returns (uint256)
    {
        return tokenLogic.allowance(owner, spender);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (tokenLogic.transferFrom(from, to, value, msg.sender)) {
            emit Transfer(from, to, value);
            return true;
        } 
        return false;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        if (tokenLogic.approve(spender, value, msg.sender)) {
            emit Approval(msg.sender, spender, value);
            return true;
        }
        return false;
    }

    function totalSupply() public view returns (uint256) {
        return tokenLogic.totalSupply();
    }
    
    function balanceOf(address who) public view returns (uint256) {
        return tokenLogic.balanceOf(who);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if (tokenLogic.transfer(to, value, msg.sender)) {
            emit Transfer(msg.sender, to, value);
            return true;
        } 
        return false;
    }

}