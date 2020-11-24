 

library TokenLib {
    struct Token {
        string identity;
        address owner;
    }

    function id(Token storage self) returns (bytes32) {
        return sha3(self.identity);
    }

    function generateId(string identity) returns (bytes32) {
        return sha3(identity);
    }

    event Transfer(address indexed _from, address indexed _to, bytes32 _value);
    event Approval(address indexed _owner, address indexed _spender, bytes32 _value);

    function logApproval(address _owner, address _spender, bytes32 _value) {
        Approval(_owner, _spender, _value);
    }

    function logTransfer(address _from, address _to, bytes32 _value) {
        Transfer(_from, _to, _value);
    }
}

contract TokenInterface {
     
    event Mint(address indexed _to, bytes32 _id);
    event Destroy(bytes32 _id);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MinterAdded(address who);
    event MinterRemoved(address who);

     
     
     
     
    function mint(address _to, string _identity) returns (bool success);

     
     
    function destroy(bytes32 _id) returns (bool success);

     
     
    function addMinter(address who) returns (bool);

     
     
    function removeMinter(address who) returns (bool);

     

     
    function totalSupply() returns (uint supply);

     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);
    function transfer(address _to, bytes32 _value) returns (bool success);

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, bytes32 _value) returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);
    function approve(address _spender, bytes32 _value) returns (bool success);

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     
     
     
    function isTokenOwner(address _owner) constant returns (bool);

     
     
    function identityOf(bytes32 _id) constant returns (string identity);

     
     
    function ownerOf(bytes32 _id) constant returns (address owner);
}

contract Devcon2Token is TokenInterface {
    using TokenLib for TokenLib.Token;

     
    mapping (address => bool) public minters;
    uint constant _END_MINTING = 1474502400;   

    function END_MINTING() constant returns (uint) {
        return _END_MINTING;
    }

    function Devcon2Token() {
        minters[msg.sender] = true;
        MinterAdded(msg.sender);
    }

     
    uint numTokens;

     
    mapping (bytes32 => TokenLib.Token) tokens;

     
    mapping (address => bytes32) public ownedToken;

     
    mapping (address => mapping (address => bytes32)) approvals;

     
     
     
     
    function mint(address _to, string _identity) returns (bool success) {
         
        if (now >= _END_MINTING) throw;

         
        if (!minters[msg.sender]) return false;

         
        if (ownedToken[_to] != 0x0) return false;

         
        bytes32 id = TokenLib.generateId(_identity);
        var token = tokens[id];

         
        if (id == token.id()) return false;

         
        token.owner = _to;
        token.identity = _identity;
        ownedToken[_to] = id;

         
        Mint(_to, id);

         
        numTokens += 1;

        return true;
    }

     
     
    function destroy(bytes32 _id) returns (bool success) {
         
        if (now >= _END_MINTING) throw;

         
        if (!minters[msg.sender]) return false;

         
        var tokenToDestroy = tokens[_id];

         
        ownedToken[tokenToDestroy.owner] = 0x0;

         
        tokenToDestroy.identity = '';
        tokenToDestroy.owner = 0x0;

         
        Destroy(_id);

         
        numTokens -= 1;
        
        return true;
    }

     
     
    function addMinter(address who) returns (bool) {
         
        if (now >= _END_MINTING) throw;

         
        if (!minters[msg.sender]) return false;

        minters[who] = true;

         
        MinterAdded(who);

        return true;
    }

     
     
    function removeMinter(address who) returns (bool) {
         
        if (!minters[msg.sender]) return false;

        minters[who] = false;

         
        MinterRemoved(who);

        return true;
    }

     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        return transfer(_to, bytes32(_value));
    }

    function transfer(address _to, bytes32 _value) returns (bool success) {
         
        if (_value == 0x0) return false;

         
        if (tokens[_value].id() != _value) return false;

         
        if (ownedToken[_to] != 0x0) return false;

         
        var tokenToTransfer = tokens[_value];

         
        if (tokenToTransfer.owner != msg.sender) return false;

         
        tokenToTransfer.owner = _to;
        ownedToken[msg.sender] = 0x0;
        ownedToken[_to] = _value;

         
         
        TokenLib.logTransfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        return transferFrom(_from, _to, bytes32(_value));
    }

    function transferFrom(address _from, address _to, bytes32 _value) returns (bool success) {
         
        if (_value == 0x0) return false;

         
        if (tokens[_value].id() != _value) return false;

         
        if (ownedToken[_to] != 0x0) return false;

         
        var tokenToTransfer = tokens[_value];

         
        if (tokenToTransfer.owner != _from) return false;
        if (ownedToken[_from] != _value) return false;

         
        if (approvals[_from][msg.sender] != _value) return false;

         
        tokenToTransfer.owner = _to;
        ownedToken[_from] = 0x0;
        ownedToken[_to] = _value;
        approvals[_from][msg.sender] = 0x0;

         
        Transfer(_from, _to, uint(_value));
        TokenLib.logTransfer(_from, _to, _value);

        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        return approve(_spender, bytes32(_value));
    }

    function approve(address _spender, bytes32 _value) returns (bool success) {
         
        if (_value == 0x0) return false;

         
        if (tokens[_value].id() != _value) return false;

         
        var tokenToApprove = tokens[_value];

         
        if (tokenToApprove.owner != msg.sender) return false;
        if (ownedToken[msg.sender] != _value) return false;

         
        approvals[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, uint(_value));
        TokenLib.logApproval(msg.sender, _spender, _value);

        return true;
    }

     
     
    function totalSupply() returns (uint supply) {
        return numTokens;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return uint(ownedToken[_owner]);
    }

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return uint(approvals[_owner][_spender]);
    }

     
     
     
    function isTokenOwner(address _owner) constant returns (bool) {
        return (ownedToken[_owner] != 0x0 && tokens[ownedToken[_owner]].owner == _owner);
    }

     
     
    function identityOf(bytes32 _id) constant returns (string identity) {
        return tokens[_id].identity;
    }

     
     
    function ownerOf(bytes32 _id) constant returns (address owner) {
        return tokens[_id].owner;
    }
}