 

pragma solidity ^0.4.21;

 

 
library SafeMath {
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

 

 
contract ERC20 {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract Stampable is ERC20 {
    using SafeMath for uint256;

     
    struct TokenBalance {
        uint256 amount;
        uint index;
    }

     
    struct AddressBalance {
        mapping (uint256 => TokenBalance) tokens;
        uint256[] tokenIndex;
    }

     
    mapping (address => AddressBalance) balances;

     
    mapping (address => uint256) ownershipCount;

     
    mapping (address => bool) public stampingWhitelist;

     
    modifier onlyStampingWhitelisted() {
        require(stampingWhitelist[msg.sender]);
        _;
    }

     
    event TokenStamp (address indexed from, uint256 tokenStamped, uint256 stamp, uint256 amt);

     
    function stampToken (uint256 _tokenToStamp, uint256 _stamp, uint256 _amt)
        onlyStampingWhitelisted
        public returns (bool) {
        require(_amt <= balances[msg.sender].tokens[_tokenToStamp].amount);

         
        removeToken(msg.sender, _tokenToStamp, _amt);

         
        addToken(msg.sender, _stamp, _amt);

         
        emit TokenStamp(msg.sender, _tokenToStamp, _stamp, _amt);

        return true;
    }

    function addToken(address _owner, uint256 _token, uint256 _amount) internal {
         
        if (balances[_owner].tokens[_token].amount == 0) {
            balances[_owner].tokens[_token].index = balances[_owner].tokenIndex.push(_token) - 1;
        }
        
         
        balances[_owner].tokens[_token].amount = balances[_owner].tokens[_token].amount.add(_amount);
        
         
        ownershipCount[_owner] = ownershipCount[_owner].add(_amount);
    }

    function removeToken(address _owner, uint256 _token, uint256 _amount) internal {
         
        ownershipCount[_owner] = ownershipCount[_owner].sub(_amount);

         
        balances[_owner].tokens[_token].amount = balances[_owner].tokens[_token].amount.sub(_amount);

         
        if (balances[_owner].tokens[_token].amount == 0) {
            uint index = balances[_owner].tokens[_token].index;
            uint256 lastCoin = balances[_owner].tokenIndex[balances[_owner].tokenIndex.length - 1];
            balances[_owner].tokenIndex[index] = lastCoin;
            balances[_owner].tokens[lastCoin].index = index;
            balances[_owner].tokenIndex.length--;
             
            delete balances[_owner].tokens[_token];
        }
    }
}

 

contract TestCoin is Stampable {
    using SafeMath for uint256;
    
     
    address public owner;

     
    mapping (address => mapping (address => uint256)) public allowed;

    event TokenTransfer (address indexed from, address indexed to, uint256 tokenId, uint256 value);
    event MintTransfer  (address indexed from, address indexed to, uint256 originalTokenId, uint256 tokenId, uint256 value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function TestCoin() public {
        owner = 0x8aBF67F3d00091FA2C6D7abBe0de891311111111;
        name = "TestCoinFC";
        symbol = "TCFC";
        decimals = 4;
        
         
        totalSupply = 6e8 * uint256(10) ** decimals; 

         
        stampingWhitelist[owner] = true;

         
        addToken(owner, 0, totalSupply);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipCount[_owner];
    }

     
    function balanceOfToken(address _owner, uint256 _tokenId) public view returns (uint256 balance) {
        return balances[_owner].tokens[_tokenId].amount;
    }

     
    function tokensOwned(address _owner) public view returns (uint256[] tokens) {
        return balances[_owner].tokenIndex;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= totalSupply);
        require(_value <= ownershipCount[msg.sender]);

         
        uint256 _tokensToTransfer = uint256(_value);

         
        require(transferAny(msg.sender, _to, _tokensToTransfer));

         
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferToken(address _to, uint256 _tokenId, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender].tokens[_tokenId].amount);
        
         
        internalTransfer(msg.sender, _to, _tokenId, _value);
        
         
        emit TokenTransfer(msg.sender, _to, _tokenId, _value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferTokens(address _to, uint256[] _tokenIds, uint256[] _values) public returns (bool) {
        require(_to != address(0));
        require(_tokenIds.length == _values.length);
        require(_tokenIds.length < 100);  

         
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_values[i] > 0);
            require(_values[i] <= balances[msg.sender].tokens[_tokenIds[i]].amount);
        }

         
        for (i = 0; i < _tokenIds.length; i++) {
            require(internalTransfer(msg.sender, _to, _tokenIds[i], _values[i]));
            emit TokenTransfer(msg.sender, _to, _tokenIds[i], _values[i]);
            emit Transfer(msg.sender, _to, _values[i]);
        }
    
        return true; 
    }

     
    function transferAny(address _from, address _to, uint256 _value) private returns (bool) {
         
         
         
         
         
        uint256 _tokensToTransfer = _value;
        while (_tokensToTransfer > 0) {
            uint256 tokenId = balances[_from].tokenIndex[0];
            uint256 tokenBalance = balances[_from].tokens[tokenId].amount;

            if (tokenBalance >= _tokensToTransfer) {
                require(internalTransfer(_from, _to, tokenId, _tokensToTransfer));
                _tokensToTransfer = 0;
            } else {
                _tokensToTransfer = _tokensToTransfer - tokenBalance;
                require(internalTransfer(_from, _to, tokenId, tokenBalance));
            }
        }

        return true;
    }

     
    function internalTransfer(address _from, address _to, uint256 _tokenId, uint256 _value) private returns (bool) {
         
        removeToken(_from, _tokenId, _value);

         
        addToken(_to, _tokenId, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= ownershipCount[_from]);
        require(_value <= allowed[_from][msg.sender]);

         
        uint256 _castValue = uint256(_value);

         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

         
        require(transferAny(_from, _to, _castValue));

         
        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function mintTransfer(address _to, uint256 _tokenToStamp, uint256 _stamp, uint256 _amount) public 
        onlyStampingWhitelisted returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender].tokens[_tokenToStamp].amount);

         
        removeToken(msg.sender, _tokenToStamp, _amount);

         
        addToken(_to, _stamp, _amount);

        emit MintTransfer(msg.sender, _to, _tokenToStamp, _stamp, _amount);
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

     
    function addToWhitelist(address _addr) public
        onlyOwner {
        stampingWhitelist[_addr] = true;
    }

     
    function removeFromWhitelist(address _addr) public
        onlyOwner {
        stampingWhitelist[_addr] = false;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint _value = allowed[msg.sender][_spender];
        if (_subtractedValue > _value) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = _value.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}