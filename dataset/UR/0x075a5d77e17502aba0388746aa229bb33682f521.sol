 

pragma solidity ^0.4.11;


 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}



 
contract Authorizable {

    address[] authorizers;
    mapping(address => uint) authorizerIndex;

     
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

     
    function Authorizable() {
        authorizers.length = 2;
        authorizers[1] = msg.sender;
        authorizerIndex[msg.sender] = 1;
    }

     
    function getAuthorizer(uint authorizerIndex) external constant returns(address) {
        return address(authorizers[authorizerIndex + 1]);
    }

     
    function isAuthorized(address _addr) constant returns(bool) {
        return authorizerIndex[_addr] > 0;
    }

     
    function addAuthorized(address _addr) external onlyAuthorized {
        authorizerIndex[_addr] = authorizers.length;
        authorizers.length++;
        authorizers[authorizers.length - 1] = _addr;
    }

}

 
library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        require(assertion);
    }
}


 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

     
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

}




 
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) {

         
         
         
         
        require( ! ((_value != 0) && (allowed[msg.sender][_spender] != 0)) );

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}






 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint value);
    event MintFinished();

    bool public mintingFinished = false;
    uint public totalSupply = 0;


    modifier canMint() {
        require(! mintingFinished);
        _;
    }

     
    function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}






 
contract TopCoin is MintableToken {

    string public name = "TopCoin";
    string public symbol = "TPC";
    uint public decimals = 6;

    bool public tradingStarted = false;

     
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

     
    function startTrading() onlyOwner {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) hasStartedTrading {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
        super.transferFrom(_from, _to, _value);
    }

}


 
contract TopCoinDistribution is Ownable, Authorizable {
    using SafeMath for uint;
    event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
    event AuthorizedCreate(address recipient, uint pay_amount);
    event TopCoinSaleClosed();

    TopCoin public token = new TopCoin();

    address public multisigVault;

    uint public hardcap = 87500 ether;

    uint public rate = 3600*(10 ** 6);  

    uint totalToken = 2100000000 * (10 ** 6);  

    uint public authorizeMintToken = 210000000 * (10 ** 6);  

    uint public altDeposits = 0;  

    uint public start = 1504008000;  

    address partenersAddress = 0x6F3c01E350509b98665bCcF7c7D88C120C1762ef;  
    address operationAddress = 0xb5B802F753bEe90C969aD27a94Da5C179Eaa3334;  
    address technicalAddress = 0x62C1eC256B7bb10AA53FD4208454E1BFD533b7f0;  

     
    modifier saleIsOn() {
        require(now > start && now < start + 28 days);
        _;
    }

     
    modifier isUnderHardCap() {
        require(multisigVault.balance + msg.value + altDeposits <= hardcap);
        _;
    }

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
        size := extcodesize(_addr)
        }
        return size > 0;
    }

     
    function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
        require(!isContract(recipient));
        uint tokens = rate.mul(msg.value).div(1 ether);
        token.mint(recipient, tokens);
        require(multisigVault.send(msg.value));
        TokenSold(recipient, msg.value, tokens, rate);
    }

     
    function setAuthorizeMintToken(uint _authorizeMintToken) public onlyOwner {
        authorizeMintToken = _authorizeMintToken;
    }

     
    function setAltDeposit(uint totalAltDeposits) public onlyOwner {
        altDeposits = totalAltDeposits;
    }

     
    function setRate(uint _rate) public onlyOwner {
        rate = _rate;
    }


     
    function authorizedCreateTokens(address recipient, uint _tokens) public onlyAuthorized {
        uint tokens = _tokens * (10 ** 6);
        uint totalSupply = token.totalSupply();
        require(totalSupply + tokens <= authorizeMintToken);
        token.mint(recipient, tokens);
        AuthorizedCreate(recipient, tokens);
    }

     
    function setHardCap(uint _hardcap) public onlyOwner {
        hardcap = _hardcap;
    }

     
    function setStart(uint _start) public onlyOwner {
        start = _start;
    }

     
    function setMultisigVault(address _multisigVault) public onlyOwner {
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

     
    function finishMinting() public onlyOwner {
        uint issuedTokenSupply = token.totalSupply();
        uint partenersTokens = totalToken.mul(20).div(100);
        uint technicalTokens = totalToken.mul(30).div(100);
        uint operationTokens = totalToken.mul(20).div(100);

        token.mint(partenersAddress, partenersTokens);
        token.mint(technicalAddress, technicalTokens);
        token.mint(operationAddress, operationTokens);

        uint restrictedTokens = totalToken.sub(issuedTokenSupply).sub(partenersTokens).sub(technicalTokens).sub(operationTokens);
        token.mint(multisigVault, restrictedTokens);
        token.finishMinting();
        token.transferOwnership(owner);
        TopCoinSaleClosed();
    }

     
    function retrieveTokens(address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        token.transfer(multisigVault, token.balanceOf(this));
    }

     
    function() external payable {
        createTokens(msg.sender);
    }

}