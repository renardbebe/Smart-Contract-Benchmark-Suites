 

pragma solidity ^0.5.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0);
        c = a / b;
        return c;
    }
}


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract FSGToken is owned {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 6; 
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

     
    constructor() public {
        totalSupply = 1e9 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                   
        name = "Four S Gaming";                                      
        symbol = "FSG";
    }

    function balanceOfcheck(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowancecheck(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
    
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowance[msg.sender][_spender] = 0;
        } else {
          allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
      }

     
    function mintToken(uint256 mintedAmount) onlyOwner public {
        balanceOf[owner] += mintedAmount.mul(1e6);
        totalSupply += mintedAmount.mul(1e6);
        emit Transfer(address(this), owner, mintedAmount);
    }

    function burn(uint256 _value)onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[owner] -= _value.mul(1e6);             
        totalSupply -= _value.mul(1e6);                       
        emit Burn(owner, _value);
        return true;
    }
    
    mapping(bytes => bool) signatures;
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    
     
    function transferPreSigned(bytes memory _signature,address _to,uint256 _value,uint256 _fee,uint _nonc
    )public returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);
        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee,_nonc);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        balanceOf[from] = balanceOf[from].sub(_value).sub(_fee);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        signatures[_signature] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
    
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint _nonc
    )
        public
        pure
        returns (bytes32)
    {
         
        return (keccak256(abi.encodePacked(bytes4(0x48664c16), _token, _to, _value, _fee,_nonc)));
    }
    
    function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
      bytes32  r;
      bytes32  s;
      uint8 v;
        
      if (sig.length != 65) {
        return (address(0));
      }
        
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }
        
      if (v < 27) {
        v += 27;
      }
        
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }
}