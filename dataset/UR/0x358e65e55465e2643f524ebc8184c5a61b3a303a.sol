 

pragma solidity >=0.4.22 <0.7.0;

contract OCCToken{


     
     
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
     
     

     
     
    string public symbol = "OCC";
    string public name = "O‘Community Chain";
    uint8 public decimals = 18;
    uint public totalSupply = 21e24;
    bool public allowTransfer = true;

    mapping(address => uint) private balances;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    address private foundingTeamAddress = 0x6345613c3EF87D1e62E4f0eA043Bff46834f4D40;
    address private communityMiningAddress = 0xd70B8174Be3B49D203f3AA2311D6036422D09625;
    address private communityNodeLockAddress = 0x09e042d647E7E082Fc1b7Ae99FdFf2E9617Dab9C;
    address private mediaAnnouncementAddress = 0x6FBe46eb6327f131C0607A6eC77cA643B858D712;
    address private communityAirdropIncentivesAddress = 0xCE6E467ac481938F30824Af4244B9D7A2b397Ff4;
    
    address payable private exchangeAddress = 0x02505896bD3d99E42DC955304d1aFb6B83eb3a71;
    address payable private ticketAddress = 0xf2556DBD19CD4581901b05e40062664e9277c500;

    bool public allowExchange = true;
    uint public exchangeEthMin = 1e16;
    uint public exchangeRate = 90;

    constructor() public {
        owner = msg.sender;

        balances[foundingTeamAddress] = 63e23;
        emit Transfer(address(this), foundingTeamAddress, 21e23);
        emit Transfer(address(this), foundingTeamAddress, 42e23);

        balances[communityMiningAddress] = 735e22;
        emit Transfer(address(this), communityMiningAddress, 735e22);

        balances[communityNodeLockAddress] = 42e23;
        emit Transfer(address(this), communityNodeLockAddress, 42e23);

        balances[mediaAnnouncementAddress] = 105e22;
        emit Transfer(address(this), mediaAnnouncementAddress, 105e22);

        balances[communityAirdropIncentivesAddress] = 21e23;
        emit Transfer(address(this), communityAirdropIncentivesAddress, 21e23);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        balance = balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public pure returns (uint remaining) {
        require(tokenOwner != spender);
         
        remaining = 0;
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != msg.sender);
        require(to != address(this));
        require(allowTransfer);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(msg.sender, to, tokens);
        success = true;
    }
    function approve(address spender, uint tokens) public pure returns (bool success) {
        require(spender == spender);
        require(tokens == tokens);
         
        success = false;
    }
    function transferFrom(address from, address to, uint tokens) public pure returns (bool success) {       
        require(from != to);
        require(tokens == tokens);
         
        success = false;
    }
     
     

     
    function () external payable {
        require(allowExchange);
        require(msg.value >= exchangeEthMin);

        uint tokens = safeMul(msg.value, exchangeRate);
        uint eth = safeDiv(tokens, 100);
        exchangeAddress.transfer(eth);
        ticketAddress.transfer(msg.value - eth);
    }
    function chExchangeAddress(address payable _exchangeAddress) external onlyOwner {
        exchangeAddress = _exchangeAddress;
    }
    function chTicketAddress(address payable _ticketAddress) external onlyOwner {
        ticketAddress = _ticketAddress;
    }
    function chExchangeRage(uint _exchangeRate) external onlyOwner {
        exchangeRate = _exchangeRate;
    }
    function chExchangeEthMin(uint _exchangeEthMin) external onlyOwner {
        exchangeEthMin = _exchangeEthMin;
    }
    function chAllowExchange(bool _allowExchange) external onlyOwner {
        allowExchange =  _allowExchange;
    }
    function chAllowTransfer(bool _allowTransfer) external onlyOwner {
        allowTransfer = _allowTransfer;
    }
     
    function clearEth(address payable addr) external onlyOwner {
        addr.transfer(address(this).balance);
    }
    function sendTokens(address[] calldata to, uint[] calldata tokens) external {
        if (to.length == tokens.length) {
            uint count = 0;
            for (uint i = 0; i < tokens.length; i++) {
                count = safeAdd(count, tokens[i]);
            }
            if (count <= balances[msg.sender]) {
                balances[msg.sender] = safeSub(balances[msg.sender], count);
                for (uint i = 0; i < to.length; i++) {
                    balances[to[i]] = safeAdd(balances[to[i]], tokens[i]);
                    emit Transfer(msg.sender, to[i], tokens[i]);
                }
            }
        }
    }
    function sendEths(address payable[]  calldata to, uint[] calldata values) external payable{
        require(to.length == values.length);
        uint count = 0;
        for (uint i = 0; i < values.length; i++) {
            count = safeAdd(count, values[i]);
        }
        require(count <= msg.value);
        for (uint i = 0; i < to.length; i++) {
            to[i].transfer(values[i]);
        }
        msg.sender.transfer(msg.value - count);
    }
}