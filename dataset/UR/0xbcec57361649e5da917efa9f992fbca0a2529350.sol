 

pragma solidity ^0.4.11;

 
contract ERC20 {

     
    function totalSupply() public constant returns (uint256);

     
    function balanceOf(address _owner) public constant returns (uint256);

     
    function transfer(address _to, uint256 _value) public returns (bool);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

     
    function approve(address _spender, uint256 _value) public returns (bool);

     
    function allowance(address _owner, address _spender) public constant returns (uint256);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract SafeMath {

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract StandardToken is ERC20, SafeMath {

    uint256 internal globalSupply;

     
    mapping (address => uint256) internal balanceMap;
    mapping (address => mapping (address => uint256)) internal allowanceMap;

     
    function isToken() public pure returns (bool) {
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require (_to != 0x0);                                            
        require (balanceMap[msg.sender] >= _value);                       
        require (balanceMap[_to] + _value >= balanceMap[_to]);             
        balanceMap[msg.sender] = safeSub(balanceMap[msg.sender], _value);  
        balanceMap[_to] = safeAdd(balanceMap[_to], _value);                
        Transfer(msg.sender, _to, _value);                               
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require (_to != 0x0);                                            
        require (balanceMap[_from] >= _value);                            
        require (balanceMap[_to] + _value >= balanceMap[_to]);             
        require (_value <= allowanceMap[_from][msg.sender]);                
        balanceMap[_from] = safeSub(balanceMap[_from], _value);            
        balanceMap[_to] = safeAdd(balanceMap[_to], _value);                

        uint256 _allowance = allowanceMap[_from][msg.sender];
        allowanceMap[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() public constant returns (uint256) {
        return globalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balanceMap[_owner];
    }

     
    function setIcoAddress(address _icoAddress) external onlyOwner {
        require (icoAddress == address(0x0));

        icoAddress = _icoAddress;
        balanceMap[icoAddress] = 80 * oneMillionAls;

        IcoAddressSet(icoAddress);
    }

     
    function burnIcoTokens() external onlyAfterIco {
        require (!icoTokensWereBurned);
        icoTokensWereBurned = true;

        uint256 tokensToBurn = balanceMap[icoAddress];
        if (tokensToBurn > 0)
        {
            balanceMap[icoAddress] = 0;
            globalSupply = safeSub(globalSupply, tokensToBurn);
        }

        Burned(icoAddress, tokensToBurn);
    }

    function allocateTeamAndPartnerTokens(address _teamAddress, address _partnersAddress) external onlyOwner {
        require (icoTokensWereBurned);
        require (!teamTokensWereAllocated);

        uint256 oneTenth = safeDiv(globalSupply, 8);

        balanceMap[_teamAddress] = oneTenth;
        globalSupply = safeAdd(globalSupply, oneTenth);

        balanceMap[_partnersAddress] = oneTenth;
        globalSupply = safeAdd(globalSupply, oneTenth);

        teamTokensWereAllocated = true;

        TeamAndPartnerTokensAllocated(_teamAddress, _partnersAddress);
    }

     
    event IcoAddressSet(address _icoAddress);

     
    event Burned(address _address, uint256 _amount);

     
    event TeamAndPartnerTokensAllocated(address _teamAddress, address _partnersAddress);
}