 

pragma solidity ^0.4.16;


interface Presale {
    function tokenAddress() constant returns (address);
}


interface Crowdsale {
    function tokenAddress() constant returns (address);
}


contract Admins {
    address public admin1;

    address public admin2;

    address public admin3;

    function Admins(address a1, address a2, address a3) public {
        admin1 = a1;
        admin2 = a2;
        admin3 = a3;
    }

    modifier onlyAdmins {
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
        _;
    }

    function setAdmin(address _adminAddress) onlyAdmins public {

        require(_adminAddress != admin1);
        require(_adminAddress != admin2);
        require(_adminAddress != admin3);

        if (admin1 == msg.sender) {
            admin1 = _adminAddress;
        }
        else
        if (admin2 == msg.sender) {
            admin2 = _adminAddress;
        }
        else
        if (admin3 == msg.sender) {
            admin3 = _adminAddress;
        }
    }

}


contract TokenERC20 {
     
    string public name;

    string public symbol;

    uint8 public decimals = 18;

    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
         
        balanceOf[this] = totalSupply;
         
        name = tokenName;
         
        symbol = tokenSymbol;
         
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


contract TrimpoToken is Admins, TokenERC20 {

    uint public transferredManually = 0;

    uint public transferredPresale = 0;

    uint public transferredCrowdsale = 0;

    address public presaleAddr;

    address public crowdsaleAddr;

    modifier onlyPresale {
        require(msg.sender == presaleAddr);
        _;
    }

    modifier onlyCrowdsale {
        require(msg.sender == crowdsaleAddr);
        _;
    }


    function TrimpoToken(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol,
    address a1,
    address a2,
    address a3
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) Admins(a1, a2, a3) public {}


    function transferManual(address _to, uint _value) onlyAdmins public {
        _transfer(this, _to, _value);
        transferredManually += _value;
    }

    function setPresale(address _presale) onlyAdmins public {
        require(_presale != 0x0);
        bool allow = false;
        Presale newPresale = Presale(_presale);

        if (newPresale.tokenAddress() == address(this)) {
            presaleAddr = _presale;
        }
        else {
            revert();
        }

    }

    function setCrowdsale(address _crowdsale) onlyAdmins public {
        require(_crowdsale != 0x0);
        Crowdsale newCrowdsale = Crowdsale(_crowdsale);

        if (newCrowdsale.tokenAddress() == address(this)) {

            crowdsaleAddr = _crowdsale;
        }
        else {
            revert();
        }

    }

    function transferPresale(address _to, uint _value) onlyPresale public {
        _transfer(this, _to, _value);
        transferredPresale += _value;
    }

    function transferCrowdsale(address _to, uint _value) onlyCrowdsale public {
        _transfer(this, _to, _value);
        transferredCrowdsale += _value;
    }

}