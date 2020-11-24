 

pragma solidity ^0.4.18;


 
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
contract MultiTokenBasics {

    function totalSupply(uint256 _tokenId) public view returns (uint256);

    function balanceOf(uint256 _tokenId, address _owner) public view returns (uint256);

    function allowance(uint256 _tokenId, address _owner, address _spender) public view returns (uint256);

    function transfer(uint256 _tokenId, address _to, uint256 _value) public returns (bool);

    function transferFrom(uint256 _tokenId, address _from, address _to, uint256 _value) public returns (bool);

    function approve(uint256 _tokenId, address _spender, uint256 _value) public returns (bool);


    event Transfer(uint256 indexed tokenId, address indexed from, address indexed to, uint256 value);
    event Approval(uint256 indexed tokenId, address indexed owner, address indexed spender, uint256 value);

}

contract MultiToken is Ownable, MultiTokenBasics {
    using SafeMath for uint256;

    mapping(uint256 => mapping(address => mapping(address => uint256))) private allowed;
    mapping(uint256 => mapping(address => uint256)) private balance;
    mapping(uint256 => uint256) private totalSupply_;


    uint8 public decimals = 18;
    uint256 public mask = 0xffffffff;



     

    modifier existingToken(uint256 _tokenId) {
        require(totalSupply_[_tokenId] > 0 && (_tokenId & mask == _tokenId));
        _;
    }

     

    modifier notExistingToken(uint256 _tokenId) {
        require(totalSupply_[_tokenId] == 0 && (_tokenId & mask == _tokenId));
        _;
    }





     

    function createNewSubtoken(uint256 _tokenId, address _to, uint256 _value) notExistingToken(_tokenId) onlyOwner() public returns (bool) {
        require(_value > 0);
        balance[_tokenId][_to] = _value;
        totalSupply_[_tokenId] = _value;
        Transfer(_tokenId, address(0), _to, _value);
        return true;
    }


     

    function totalSupply(uint256 _tokenId) existingToken(_tokenId) public view returns (uint256) {
        return totalSupply_[_tokenId];
    }

     

    function balanceOf(uint256 _tokenId, address _owner) existingToken(_tokenId) public view returns (uint256) {
        return balance[_tokenId][_owner];
    }



     

    function allowance(uint256 _tokenId, address _owner, address _spender) existingToken(_tokenId) public view returns (uint256) {
        return allowed[_tokenId][_owner][_spender];
    }



     

    function transfer(uint256 _tokenId, address _to, uint256 _value) existingToken(_tokenId) public returns (bool) {
        require(_to != address(0));
        var _sender = msg.sender;
        var balances = balance[_tokenId];
        require(_to != address(0));
        require(_value <= balances[_sender]);

         
        balances[_sender] = balances[_sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_tokenId, _sender, _to, _value);
        return true;
    }


     

    function transferFrom(uint256 _tokenId, address _from, address _to, uint256 _value) existingToken(_tokenId) public returns (bool) {
        address _sender = msg.sender;
        var balances = balance[_tokenId];
        var tokenAllowed = allowed[_tokenId];

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= tokenAllowed[_from][_sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        tokenAllowed[_from][_sender] = tokenAllowed[_from][_sender].sub(_value);
        Transfer(_tokenId, _from, _to, _value);
        return true;
    }



     



    function approve(uint256 _tokenId, address _spender, uint256 _value) public returns (bool) {
        var _sender = msg.sender;
        allowed[_tokenId][_sender][_spender] = _value;
        Approval(_tokenId, _sender, _spender, _value);
        return true;
    }


}