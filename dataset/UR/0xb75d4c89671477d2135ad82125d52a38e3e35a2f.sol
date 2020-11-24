 

pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract CrypteloERC20 {
     
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    uint256 public totalSupplyICO;
    uint256 public totalSupplyPrivateSale;
    uint256 public totalSupplyTeamTokens;
    uint256 public totalSupplyExpansionTokens;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    function CrypteloERC20() public {
        name = "CRL";
        symbol = "CRL";
        decimals = 8;
        totalSupply = 500000000 * ( 10 ** decimals);
        totalSupplyICO = 150000000 * ( 10 ** decimals);
        totalSupplyPrivateSale = 100000000 * ( 10 ** decimals);
        totalSupplyTeamTokens = 125000000 * ( 10 ** decimals);
        totalSupplyExpansionTokens = 125000000 * ( 10 ** decimals);

        address privateW = 0x2F2Aed5Bb8D2b555C01f143Ec32F6869581b0053;
        address ICOW = 0x163Eae60A768f12ff94d4d631B563DB04aEF7A57;
        address companyW = 0x3AF0511735C5150f0E025B8fFfDc0bD86985DFd5;
        address expansionW = 0x283872929a79C86efCf76198f15A3abE0856dCD7;

        balanceOf[ICOW] = totalSupplyICO ;
        balanceOf[privateW] = totalSupplyPrivateSale;
        balanceOf[companyW] = totalSupplyTeamTokens;
        balanceOf[expansionW] = totalSupplyExpansionTokens;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
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

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}