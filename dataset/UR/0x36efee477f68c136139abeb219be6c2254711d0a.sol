 

pragma solidity ^0.4.13;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract FLiK is owned {
     
    string public standard = 'FLiK 0.1';
    string public name;
    string public symbol;
    uint8 public decimals = 14;
    uint256 public totalSupply;
    bool public locked;
    uint256 public icoSince;
    uint256 public icoTill;
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event IcoFinished();

    uint256 public buyPrice = 1;

     
    function FLiK(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 _icoSince,
        uint256 _icoTill
    ) {
        totalSupply = initialSupply;
        
        balanceOf[this] = totalSupply / 100 * 90;            
        name = tokenName;                                    
        symbol = tokenSymbol;                                

        balanceOf[msg.sender] = totalSupply / 100 * 10;      

        Transfer(this, msg.sender, balanceOf[msg.sender]);

        if(_icoSince == 0 && _icoTill == 0) {
            icoSince = 1503187200;
            icoTill = 1505865600;
        }
        else {
            icoSince = _icoSince;
            icoTill = _icoTill;
        }
    }

     
    function transfer(address _to, uint256 _value) {
        require(locked == false);                             

        require(balanceOf[msg.sender] >= _value);             
        require(balanceOf[_to] + _value > balanceOf[_to]);    

        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(locked == false);                             
        require(balanceOf[_from] >= _value);                  
        require(balanceOf[_to] + _value > balanceOf[_to]);    
        require(_value <= allowance[_from][msg.sender]);      

        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);

        return true;
    }

    function buy(uint256 ethers, uint256 time) internal {
        require(locked == false);                             
        require(time >= icoSince && time <= icoTill);         
        require(ethers > 0);                                  

        uint amount = ethers / buyPrice;

        require(balanceOf[this] >= amount);                   

        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;

        Transfer(this, msg.sender, amount);
    }

    function () payable {
        buy(msg.value, now);
    }

    function internalIcoFinished(uint256 time) internal returns (bool) {
        if(time > icoTill) {
            uint256 unsoldTokens = balanceOf[this];

            balanceOf[owner] += unsoldTokens;
            balanceOf[this] = 0;

            Transfer(this, owner, unsoldTokens);

            IcoFinished();

            return true;
        }

        return false;
    }

     
    function icoFinished() onlyOwner {
        internalIcoFinished(now);
    }

     
    function transferEthers() onlyOwner {
        owner.transfer(this.balance);
    }

    function setBuyPrice(uint256 _buyPrice) onlyOwner {
        buyPrice = _buyPrice;
    }

     
    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }
}