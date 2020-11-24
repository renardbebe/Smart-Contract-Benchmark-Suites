 

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

 
 
 
 

 
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Notes is Token {

    using SafeMath for uint256;

     

     
    uint256 public constant TOTAL_SUPPLY = 2000 * (10**6) * 10**uint256(decimals);

     
    string public constant name = "NOTES";
    string public constant symbol = "NOTES";
    uint8 public constant decimals = 18;
    string public version = "1.0";

     

    address admin;
    bool public activated = false;
    mapping (address => bool) public activeGroup;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;

     

    modifier active()
    {
        require(activated || activeGroup[msg.sender]);
        _;
    }

    modifier onlyAdmin()
    {
        require(msg.sender == admin);
        _;
    }

     

    function Notes(address fund, address _admin)
    {
        admin = _admin;
        totalSupply = TOTAL_SUPPLY;
        balances[fund] = TOTAL_SUPPLY;     
        Transfer(address(this), fund, TOTAL_SUPPLY);
        activeGroup[fund] = true;   
    }

     

    function addToActiveGroup(address a) onlyAdmin {
        activeGroup[a] = true;
    }

    function activate() onlyAdmin {
        activated = true;
    }

     

    function transfer(address _to, uint256 _value) active returns (bool success) {
        require(_to != address(0));
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) active returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) active returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
 
 
 

contract Choon  {

    using SafeMath for uint256;

     
    event VoucherCashed(address indexed to, uint256 value);

     
    address notesContract;

     
    address choonAuthority;

     
    address admin;

     
    mapping(address => uint256) public payments;

     
    bool active = true;

     
    modifier onlyAdmin()
    {
        require(msg.sender == admin);
        _;
    }

    modifier isActive()
    {
        require(active);
        _;
    }

     
    function Choon(address _notesContract, address _choonAuthority, address _admin)
    {
        notesContract = _notesContract;
        choonAuthority = _choonAuthority;
        admin = _admin;
    }

    function setActive(bool _active) onlyAdmin external {
        active = _active;
    }

    function setAuthority(address _authority) onlyAdmin external {
        choonAuthority = _authority;
    }

    function shutdown() onlyAdmin external {
        active = false;
         
        uint256 balance = Notes(notesContract).balanceOf(address(this));
        Notes(notesContract).transfer(admin, balance);
    }

     
     
     
     
    function remit(address receiver, uint256 balance, bytes sig) external isActive {
         
        require(verifyBalanceProof(receiver, balance, sig));
         
        uint priorBalance = payments[receiver];
        uint owed = balance.sub(priorBalance);
        require(owed > 0);
        payments[receiver] = balance;
        Notes(notesContract).transfer(receiver, owed);
        VoucherCashed(receiver, owed);
    }

    function verifyBalanceProof(address receiver, uint256 balance, bytes sig) private returns (bool) {
        bytes memory prefix = "\x19Choon:\n32";
        bytes32 message_hash = keccak256(prefix, receiver, balance);
        address signer = ecverify(message_hash, sig);
        return (signer == choonAuthority);
    }

     
    function ecverify(bytes32 hash, bytes signature) private returns (address signature_address) {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))

         
            v := byte(0, mload(add(signature, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        signature_address = ecrecover(hash, v, r, s);

         
        require(signature_address != 0x0);

        return signature_address;
    }

}