 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


  

contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data);
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





 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public;

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}




contract Bounty0xEscrow is Ownable, ERC223ReceivingContract, Pausable {

    using SafeMath for uint256;

    mapping (address => mapping (address => uint)) public tokens;  

    event Deposit(address indexed token, address indexed user, uint amount, uint balance);
    event Distribution(address indexed token, address indexed host, address indexed hunter, uint256 amount);


    constructor() public {
    }

     
    function tokenFallback(address _from, uint _value, bytes _data) public whenNotPaused {
        address _token = msg.sender;

        tokens[_token][_from] = SafeMath.add(tokens[_token][_from], _value);
        emit Deposit(_token, _from, _value, tokens[_token][_from]);
    }

     
    function depositToken(address _token, uint _amount) public whenNotPaused {
         
        require(_token != address(0));

        ERC20(_token).transferFrom(msg.sender, this, _amount);
        tokens[_token][msg.sender] = SafeMath.add(tokens[_token][msg.sender], _amount);

        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

     
    function depositEther() public payable whenNotPaused {
        tokens[address(0)][msg.sender] = SafeMath.add(tokens[address(0)][msg.sender], msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }


    function distributeTokenToAddress(address _token, address _host, address _hunter, uint256 _amount) external onlyOwner {
        require(_hunter != address(0));
        require(tokens[_token][_host] >= _amount);

        tokens[_token][_host] = SafeMath.sub(tokens[_token][_host], _amount);

        if (_token == address(0)) {
            require(_hunter.send(_amount));
        } else {
            require(ERC20(_token).transfer(_hunter, _amount));
        }

        emit Distribution(_token, _host, _hunter, _amount);
    }

    function distributeTokenToAddressesAndAmounts(address _token, address _host, address[] _hunters, uint256[] _amounts) external onlyOwner {
        require(_host != address(0));
        require(_hunters.length == _amounts.length);

        uint256 totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(tokens[_token][_host] >= totalAmount);
        tokens[_token][_host] = SafeMath.sub(tokens[_token][_host], totalAmount);

        if (_token == address(0)) {
            for (uint i = 0; i < _hunters.length; i++) {
                require(_hunters[i].send(_amounts[i]));
                emit Distribution(_token, _host, _hunters[i], _amounts[i]);
            }
        } else {
            for (uint k = 0; k < _hunters.length; k++) {
                require(ERC20(_token).transfer(_hunters[k], _amounts[k]));
                emit Distribution(_token, _host, _hunters[k], _amounts[k]);
            }
        }
    }

    function distributeTokenToAddressesAndAmountsWithoutHost(address _token, address[] _hunters, uint256[] _amounts) external onlyOwner {
        require(_hunters.length == _amounts.length);

        uint256 totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }

        if (_token == address(0)) {
            require(address(this).balance >= totalAmount);
            for (uint i = 0; i < _hunters.length; i++) {
                require(_hunters[i].send(_amounts[i]));
                emit Distribution(_token, this, _hunters[i], _amounts[i]);
            }
        } else {
            require(ERC20(_token).balanceOf(this) >= totalAmount);
            for (uint k = 0; k < _hunters.length; k++) {
                require(ERC20(_token).transfer(_hunters[k], _amounts[k]));
                emit Distribution(_token, this, _hunters[k], _amounts[k]);
            }
        }
    }

    function distributeWithTransferFrom(address _token, address _ownerOfTokens, address[] _hunters, uint256[] _amounts) external onlyOwner {
        require(_token != address(0));
        require(_hunters.length == _amounts.length);

        uint256 totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(ERC20(_token).allowance(_ownerOfTokens, this) >= totalAmount);

        for (uint i = 0; i < _hunters.length; i++) {
            ERC20(_token).transferFrom(_ownerOfTokens, _hunters[i], _amounts[i]);

            emit Distribution(_token, this, _hunters[i], _amounts[i]);
        }
    }

     
    function approveToPullOutTokens(address _token, address _receiver, uint256 _amount) external onlyOwner {
        ERC20(_token).approve(_receiver, _amount);
    }

}