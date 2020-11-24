 

pragma solidity >=0.4.10;

 
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

contract Owned {
    address public owner;
    address newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract IToken {
    function transfer(address _to, uint _value) returns (bool);
    function balanceOf(address owner) returns(uint);
}

 
 
contract TokenReceivable is Owned {
    function claimTokens(address _token, address _to) onlyOwner returns (bool) {
        IToken token = IToken(_token);
        return token.transfer(_to, token.balanceOf(this));
    }
}

contract EventDefinitions {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, bytes32 indexed to, uint value);
    event Claimed(address indexed claimer, uint value);
}

contract Pausable is Owned {
    bool public paused;

    function pause() onlyOwner {
        paused = true;
    }

    function unpause() onlyOwner {
        paused = false;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }
}

contract Finalizable is Owned {
    bool public finalized;

    function finalize() onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        require(!finalized);
        _;
    }
}

contract Ledger is Owned, SafeMath, Finalizable {
    Controller public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;
    uint public mintingNonce;
    bool public mintingStopped;

     
    mapping(uint256 => bytes32) public proofs;

     
    mapping(address => uint256) public locked;

     
    mapping(bytes32 => bytes32) public metadata;

     
    address public burnAddress;

     
    mapping(address => bool) public bridgeNodes;

     

    function Ledger() {
    }

    function setController(address _controller) onlyOwner notFinalized {
        controller = Controller(_controller);
    }

     
    function stopMinting() onlyOwner {
        mintingStopped = true;
    }

     
    function multiMint(uint nonce, uint256[] bits) onlyOwner {
        require(!mintingStopped);
        if (nonce != mintingNonce) return;
        mintingNonce += 1;
        uint256 lomask = (1 << 96) - 1;
        uint created = 0;
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint value = bits[i]&lomask;
            balanceOf[a] = balanceOf[a] + value;
            controller.ledgerTransfer(0, a, value);
            created += value;
        }
        totalSupply += created;
    }

     

    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    function transfer(address _from, address _to, uint _value) onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value) onlyController returns (bool success) {
         
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    function setProof(uint256 _key, bytes32 _proof) onlyController {
        proofs[_key] = _proof;
    }

    function setLocked(address _key, uint256 _value) onlyController {
        locked[_key] = _value;
    }

    function setMetadata(bytes32 _key, bytes32 _value) onlyController {
        metadata[_key] = _value;
    }

     

     
    function setBurnAddress(address _address) onlyController {
        burnAddress = _address;
    }

    function setBridgeNode(address _address, bool enabled) onlyController {
        bridgeNodes[_address] = enabled;
    }
}

contract ControllerEventDefinitions {
     
    event ControllerBurn(address indexed from, bytes32 indexed to, uint value);
}

 
contract Controller is Owned, Finalizable, ControllerEventDefinitions {
    Ledger public ledger;
    Token public token;
    address public burnAddress;

    function Controller() {
    }

     


    function setToken(address _token) onlyOwner {
        token = Token(_token);
    }

    function setLedger(address _ledger) onlyOwner {
        ledger = Ledger(_ledger);
    }

     
    function setBurnAddress(address _address) onlyOwner {
        burnAddress = _address;
        ledger.setBurnAddress(_address);
        token.setBurnAddress(_address);
    }

    modifier onlyToken() {
        require(msg.sender == address(token));
        _;
    }

    modifier onlyLedger() {
        require(msg.sender == address(ledger));
        _;
    }

    function totalSupply() constant returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) constant returns (uint) {
        return ledger.balanceOf(_a);
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

     

     
     
     
    function ledgerTransfer(address from, address to, uint val) onlyLedger {
        token.controllerTransfer(from, to, val);
    }

     

    function transfer(address _from, address _to, uint _value) onlyToken returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value) onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

     

     
    function enableBurning() onlyOwner {
        token.enableBurning();
    }

     
    function disableBurning() onlyOwner {
        token.disableBurning();
    }

     

      
    function burn(address _from, bytes32 _to, uint _amount) onlyToken returns (bool success) {
        if (ledger.transfer(_from, burnAddress, _amount)) {
            ControllerBurn(_from, _to, _amount);
            token.controllerBurn(_from, _to, _amount);
            return true;
        }
        return false;
    }

     
    function claimByProof(address _claimer, bytes32[] data, bytes32[] proofs, uint256 number)
        onlyToken
        returns (bool success) {
        return false;
    }

     
    function claim(address _claimer) onlyToken returns (bool success) {
        return false;
    }
}

contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions, Pausable {
     
    string constant public name = "AION";
    uint8 constant public decimals = 8;
    string constant public symbol = "AION";
    Controller public controller;
    string public motd;
    event Motd(string message);

    address public burnAddress;  
    bool public burnable = false;

     

     
    function setMotd(string _m) onlyOwner {
        motd = _m;
        Motd(_m);
    }

    function setController(address _c) onlyOwner notFinalized {
        controller = Controller(_c);
    }

     

    function balanceOf(address a) constant returns (uint) {
        return controller.balanceOf(a);
    }

    function totalSupply() constant returns (uint) {
        return controller.totalSupply();
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return controller.allowance(_owner, _spender);
    }

    function transfer(address _to, uint _value) notPaused returns (bool success) {
        if (controller.transfer(msg.sender, _to, _value)) {
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) notPaused returns (bool success) {
        if (controller.transferFrom(msg.sender, _from, _to, _value)) {
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) notPaused returns (bool success) {
         
        if (controller.approve(msg.sender, _spender, _value)) {
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function increaseApproval (address _spender, uint _addedValue) notPaused returns (bool success) {
        if (controller.increaseApproval(msg.sender, _spender, _addedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) notPaused returns (bool success) {
        if (controller.decreaseApproval(msg.sender, _spender, _subtractedValue)) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
            return true;
        }
        return false;
    }

     
     
     
     

     

    modifier onlyController() {
        assert(msg.sender == address(controller));
        _;
    }

     
     
     

    function controllerTransfer(address _from, address _to, uint _value) onlyController {
        Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint _value) onlyController {
        Approval(_owner, _spender, _value);
    }

     
    function controllerBurn(address _from, bytes32 _to, uint256 _value) onlyController {
        Burn(_from, _to, _value);
    }

    function controllerClaim(address _claimer, uint256 _value) onlyController {
        Claimed(_claimer, _value);
    }

     
    function setBurnAddress(address _address) onlyController {
        burnAddress = _address;
    }

     
    function enableBurning() onlyController {
        burnable = true;
    }

     
    function disableBurning() onlyController {
        burnable = false;
    }

     
    modifier burnEnabled() {
        require(burnable == true);
        _;
    }

     
    function burn(bytes32 _to, uint _amount) notPaused burnEnabled returns (bool success) {
        return controller.burn(msg.sender, _to, _amount);
    }

     
    function claimByProof(bytes32[] data, bytes32[] proofs, uint256 number) notPaused burnEnabled returns (bool success) {
        return controller.claimByProof(msg.sender, data, proofs, number);
    }

     
    function claim() notPaused burnEnabled returns (bool success) {
        return controller.claim(msg.sender);
    }
}