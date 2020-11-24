 

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event LockBalance(address indexed from, address indexed to, uint tokens);
    event FreezeBalance(address indexed from, uint tokens, uint until);
    event LogUint(string key, uint value);
    event LogString(string key, string value);
    event LogAddress(string key, address value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract QARK is ERC20Interface, Owned {

     
    using SafeMath for uint;

     
    string public symbol;

     
    string public  name;

     
    uint8 public decimals;

     
    uint _totalSupply;

     
    mapping(address => uint) balances;

     
    mapping(address => mapping(address => uint)) allowed;

     
    function claimReserve() public {

         
        require(msg.sender == roles[4], 'Only reserve address can claim!');

         
        if(block.timestamp < pubSaleEnd + 7 * 24 * 60 * 60){
            revert('Reserve can not be claimed before end of public sale!');
        }

         
        balances[roles[4]] = balances[roles[4]].add(balances[roles[0]]);

         
        emit Transfer(roles[0], roles[4], balances[roles[0]]);

         
        balances[roles[0]] = 0;
    }

     
    mapping(uint => address) roles;

     
    function getRoleAddress(uint _roleId) public view returns (address) {
        return roles[_roleId];
    }

     
    function setRoleAddress(uint _roleId, address _newAddress) public onlyOwner {

         
        require(balances[_newAddress] == 0, 'Only zero balance addresses can be assigned!');

         
        address _oldAddress = roles[_roleId];

         
        if(_roleId == 1 && _oldAddress != address(0)){
            revert('Exchange address MUST not be updated!');
        }

         
        if(_oldAddress == address(0)){

             
            uint initBalance = 0;

             
            if(_roleId == 0){
                initBalance = 133333200;
            }

             
            if(_roleId == 1){
                initBalance = 88888800;
            }

             
            if(_roleId == 2){
                initBalance = 44444400;
            }

             
            if(_roleId == 3){
                initBalance = 44444400;
            }

             
            if(_roleId == 4){
                initBalance = 22222200;
            }

             

             
            if(initBalance > 0){
                initBalance = initBalance * 10**uint(decimals);
                balances[_newAddress] = initBalance;
                emit Transfer(address(0), _newAddress, initBalance);

                 
                if(_roleId == 2 || _roleId == 4){
                    frozenBalances[_newAddress] = initBalance;
                    frozenTiming[_newAddress] = block.timestamp + 180 * 24 * 60 * 60;
                    emit FreezeBalance(_newAddress, initBalance, frozenTiming[_newAddress]);
                }
            }
        }

         
        if(balances[_oldAddress] > 0){

             
            balances[_newAddress] = balances[_oldAddress];

             
            emit Transfer(_oldAddress, _newAddress, balances[_oldAddress]);

             
            balances[_oldAddress] = 0;

             
            if(frozenBalances[_oldAddress] > 0){

                frozenBalances[_newAddress] = frozenBalances[_oldAddress];
                frozenTiming[_newAddress] = frozenTiming[_oldAddress];

                emit FreezeBalance(_newAddress, frozenBalances[_newAddress], frozenTiming[_newAddress]);

                frozenBalances[_oldAddress] = 0;
                frozenTiming[_oldAddress] = 0;
            }
        }

         
        roles[_roleId] = _newAddress;
    }

     
    uint public conversionRate;

    function setRate(uint _newConversionRate) public {
        require(msg.sender == roles[5], 'Only rate updater is allowed to perform this!');
        conversionRate = _newConversionRate;
    }

     
    mapping(address => uint256) lockedBalances;

     
    uint public pubSaleStart;

     
    uint public pubSaleEnd;

     
    uint public restrictionEnd;

     
    function setTiming(uint _pubSaleStart, uint _pubSaleEnd, uint _restrictionEnd) public onlyOwner {
        require(pubSaleStart == 0 && pubSaleEnd == 0 && restrictionEnd == 0, 'Timing only can be set once');
        pubSaleStart = _pubSaleStart;
        pubSaleEnd = _pubSaleEnd;
        restrictionEnd = _restrictionEnd;
    }

     
    constructor() public {
        symbol = "QARK";
        name = "QARK Token of QAN Platform";
        decimals = 18;
        _totalSupply = 333333000 * 10**uint(decimals);
    }

     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function lockedBalanceOf(address tokenOwner) public view returns (uint lockedBalance) {
        return lockedBalances[tokenOwner];
    }

     
    mapping(address => uint) frozenBalances;

     
    mapping(address => uint) frozenTiming;

     
    function freezeOwnTokens(uint amount, uint until) public {

         
        _autoUnfreeze();

         
        require(balances[msg.sender] - lockedBalances[msg.sender] > amount);

         
        require(frozenBalances[msg.sender] < amount);

         
        require(until > block.timestamp && until > frozenTiming[msg.sender]);

         
        frozenBalances[msg.sender] = amount;
        frozenTiming[msg.sender] = until;
    }

     
    function frozenBalanceOf(address tokenOwner) public view returns (uint frozenBalance) {
        return frozenBalances[tokenOwner];
    }

     
    function frozenTimingOf(address tokenOwner) public view returns (uint until) {
        return frozenTiming[tokenOwner];
    }

     
    function _autoUnfreeze() private {

        if(frozenBalances[msg.sender] > 0 && block.timestamp > frozenTiming[msg.sender]){
            frozenBalances[msg.sender] = 0;
        }
    }

     
    function _privTransfer(address to, uint tokens) private returns (bool success) {

         
        require(msg.sender == roles[0], 'Only private seller can make private sale TX!');

         
        require(block.timestamp < pubSaleEnd, 'No transfer from private seller after public sale!');

         
        lockedBalances[to] = lockedBalances[to].add(tokens);
        emit LockBalance(msg.sender, to, tokens);
        emit LogAddress('PrivateSaleFrom', msg.sender);
         
        return _regularTransfer(to, tokens);
    }

     
    function _pubTransfer(address to, uint tokens) private returns (bool success) {

         
        require(msg.sender != roles[0], 'Public transfer not allowed from private seller');

         
        require(balances[msg.sender].sub(lockedBalances[msg.sender]) >= tokens, 'Not enough unlocked tokens!');
        emit LogAddress('PublicSaleFrom', msg.sender);
         
        return _regularTransfer(to, tokens);
    }

     
    function _postPubTransfer(address to, uint tokens) private returns (bool success) {

         
        if(block.timestamp > pubSaleEnd + 7 * 24 * 60 * 60 && (msg.sender == roles[1] || msg.sender == roles[0])){
            revert('No transfer from exchange / private seller after public sale!');
        }

         
        if(block.timestamp < restrictionEnd && lockedBalances[msg.sender] > 0){
            emit LogAddress('RestrictedSaleFrom', msg.sender);
            return _restrictedTransfer(to, tokens);
        }
        emit LogAddress('PostPublicSaleFrom', msg.sender);
         
        return _regularTransfer(to, tokens);
    }

     
    mapping(address => address) withdrawMap;

     
    function _restrictedTransfer(address to, uint tokens) private returns (bool success) {

         
        uint totalBalance = balances[msg.sender];
        uint lockedBalance = lockedBalances[msg.sender];
        uint unlockedBalance = totalBalance.sub(lockedBalance);

         
        if(conversionRate < 39 && unlockedBalance < tokens && to != withdrawMap[msg.sender]){
            revert('Private token trading halted because of low market prices!');
        }

         
        if(unlockedBalance < tokens){

             
            uint lockables = tokens.sub(unlockedBalance);

             
            lockedBalances[to] = lockedBalances[to].add(lockables);
            emit LockBalance(msg.sender, to, lockables);

             
            lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(lockables);

             
            withdrawMap[to] = msg.sender;
        }

         
        return _regularTransfer(to, tokens);
    }

     
    function _regularTransfer(address to, uint tokens) private returns (bool success) {

         
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
    function transfer(address to, uint tokens) public returns (bool success) {

         
        _autoUnfreeze();

         
        if(frozenBalances[msg.sender] > 0 && balances[msg.sender] - frozenBalances[msg.sender] < tokens){
            revert('Frozen balance can not be spent yet, insufficient tokens!');
        }

         
        require(balances[msg.sender] >= tokens, 'Not enough liquid tokens!');

         
        if(msg.sender == roles[4] && block.timestamp < pubSaleEnd + 60 * 60 * 24 * 30 * 12){
            revert('Reserve can not be accessed before the 1 year freeze period');
        }

         
        if(msg.sender == roles[0]){
            return _privTransfer(to, tokens);
        }

         
        if(block.timestamp > pubSaleStart && block.timestamp < pubSaleEnd){
            return _pubTransfer(to, tokens);
        }

         
        if(block.timestamp > pubSaleEnd){
            return _postPubTransfer(to, tokens);
        }

         
        return false;
    }

     
    function approve(address spender, uint tokens) public returns (bool success) {

         
        if(block.timestamp < restrictionEnd){
            require(lockedBalances[msg.sender] == 0, 'This address MUST not start approval related transactions!');
            require(lockedBalances[spender] == 0, 'This address MUST not start approval related transactions!');
        }

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

         
        if(block.timestamp < restrictionEnd){
            require(lockedBalances[msg.sender] == 0, 'This address MUST not start approval related transactions!');
            require(lockedBalances[from] == 0, 'This address MUST not start approval related transactions!');
            require(lockedBalances[to] == 0, 'This address MUST not start approval related transactions!');
        }

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () external payable {

         
        revert();
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}