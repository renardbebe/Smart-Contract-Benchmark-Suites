 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

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

     
    event Burn(address indexed from, uint256 value);
    
    event Supply(uint256 supply);
     
    function CrypteloERC20() public {
        name = "CRL";
        symbol = "CRL";
        decimals = 8;
        totalSupply = 500000000;
        totalSupplyICO = 150000000;
        totalSupplyPrivateSale = 100000000;
        totalSupplyTeamTokens = 125000000;
        totalSupplyExpansionTokens = 125000000;
        
        address privateW = 0xc837Bf0664C67390aC8dA52168D0Bbdbfc53B03f;
        address ICOW = 0x25814bb26Ff76E196A2D4F69EE0A6cEd0415965c;
        address companyW = 0xA84Bff015B31e3Bc10A803F5BC5aE98e99922B68;
        address expansionW = 0x600BeAbb79885acbE606944f54ae8bC29Ec332ef;
        
        balanceOf[ICOW] = totalSupplyICO * ( 10 ** decimals);
        balanceOf[privateW] = totalSupplyPrivateSale * ( 10 ** decimals);
        balanceOf[companyW] = totalSupplyTeamTokens * ( 10 ** decimals);
        balanceOf[expansionW] = totalSupplyExpansionTokens * ( 10 ** decimals);

        Supply(totalSupplyICO * ( 10 ** decimals));
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
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
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}