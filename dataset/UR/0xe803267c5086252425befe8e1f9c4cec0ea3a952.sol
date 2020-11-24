 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function TokenERC20() public {
        totalSupply = 10000000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "Talentum";                                    
        symbol = "Talent";                                
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
}

contract  Talentum is owned, TokenERC20 {
    
    uint256 public donate_step;
    
    address maker_corp;

    mapping (address => bool) public Writers;
    
    mapping (uint16 => mapping(uint16 => mapping (uint16 => mapping (uint16 => string)))) public HolyBible;
    mapping (uint16 => string) public Country_code;

     
    function Talentum() TokenERC20()  public 
    {
        donate_step = 0;  
        maker_corp = msg.sender;
        Writers[msg.sender] = true;
    }
    
    function WriteBible(uint16 country, uint16 book, uint16 chapter, uint16 verse, string text) public
    {
        require(Writers[msg.sender]==true);
        HolyBible[country][book][chapter][verse] = text;
    }
    
    function SetWriter(address manager, bool flag) onlyOwner public
    {
        require(manager != 0x0);
        Writers[manager] = flag;
    }
    
    function ReadBible(uint16 country, uint16 book, uint16 chapter, uint16 verse ) public returns (string text)
    {
        text = HolyBible[country][book][chapter][verse];
        return text;
    }
    
    function SetCountryCode(uint16 country, string country_name) onlyOwner public
    {
        Country_code[country] = country_name;
    }
    
    function GetCountryCode(uint16 country) public returns (string country_name)
    {
        country_name = Country_code[country];
        return country_name;
    }
    
    function SetDonateStep(uint256 step) onlyOwner public
    {
        donate_step = step;
    }

    function () payable public
    {
        require(donate_step!=0);
        
        uint amount = 0;
        uint nowprice = 0;
        
        if ( donate_step == 1  )
            nowprice = 1000;  
        else
            if ( donate_step == 2 )
                nowprice = 500;  
            else
                nowprice = 100;  
                    
        amount = msg.value * nowprice; 
            
        require(balanceOf[maker_corp]>=amount);
        
        balanceOf[maker_corp] -= amount;
        balanceOf[msg.sender] += amount;                
        require(maker_corp.send(msg.value));
        Transfer(this, msg.sender, amount);               
    }


    function CoinTransfer(address _to, uint256 coin_amount) public
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);

        require(balanceOf[msg.sender] >= amount);         
        balanceOf[msg.sender] -= amount;                 
        balanceOf[_to] += amount;                 
        Transfer(msg.sender, _to, amount);               
    }

    function ForceCoinTransfer(address _from, address _to, uint256 amount) onlyOwner public
    {
        uint256 coin_amount = amount * 10 ** uint256(decimals);

        require(_from != 0x0);
        require(_to != 0x0);
        require(balanceOf[_from] >= coin_amount);         

        balanceOf[_from] -= coin_amount;                 
        balanceOf[_to] += coin_amount;                
        Transfer(_from, _to, coin_amount);               
    }
}