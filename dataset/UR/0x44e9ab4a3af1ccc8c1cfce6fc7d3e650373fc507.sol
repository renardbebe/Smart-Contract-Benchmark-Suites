 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}




 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.0;





contract CnabToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable {

    constructor()
        ERC20Burnable()
        ERC20Mintable()
        ERC20Detailed('Cannabium', 'CNAB', 18)
        ERC20()
        public
    {

         

        mint(0x243A839E28d64C2f7BaaDC91FaC22B3E79A2f6e4, 8339235460000000000000000);

        _mint(0xb5e74585a14C44f3819420831e9532F916a4f389, 2756850000000000000000000);
        _mint(0x071B03261b23b40753FAc37156d3Ff5d1ac74944, 1260800100000000000000000);
        _mint(0x03FBe5234AD39F9778dbc0F5036cC7F2974aB89c, 1250000100000000000000000);
        _mint(0x27EcF302F15d065Ff43Dcfc40Fe2c64C1e7Dd4C5, 1250000100000000000000000);
        _mint(0xeB40cA0524710301c1E32a56229044E9675847cC, 1250000000000000000000000);
        _mint(0x2E6F4E999cda38C1B7b1eDd2cE1Aef1F070ebFB4, 1250000000000000000000000);
        _mint(0xF73e47f9812c4114bEf95a7892DA0c55c7F07337, 1250000000000000000000000);
        _mint(0x3b989F8a8e328abD2fe639e36D10403E7cE6184E, 1037425380000000000000000);
        _mint(0x995938EbaB9B3A91052F6E18D6f8a2341571B78E, 900000400000000000000000);
        _mint(0xB0C0EF9bc23E4be189AF0d7128151BEaE842Bb6B, 600000000000000000000000);
        _mint(0xa8eA553C1571528cD6fD4D2c7F17B3034B3A6CF3, 550000900000000000000000);
        _mint(0x2d8Be983C7933883372793861394D89E65A93B19, 540000200000000000000000);
        _mint(0x3353cd7cdA61648323624b4BeF9dfBde54Ed14aD, 500000800000000000000000);
        _mint(0x2f6804d3927589a74651d4dBD64AB5BCC70CBd28, 500000400000000000000000);
        _mint(0x2c7226a0c80885baccE1AD0e9ea73a558595FE25, 500000300000000000000000);
        _mint(0x1ffd044183d272ad5d5F57eF54ef0991A1fcd77b, 250000700000000000000000);
        _mint(0x2929C9e2934cC476Ec31a8Fc26F4cc2C4F6DcE92, 250000700000000000000000);
        _mint(0xbb7A1f75B2919fb2c6818DCebAb54254da59f911, 250000000000000000000000);
        _mint(0x65946d8D2E9c4882F6d0FEAED542008114f42EEB, 178755820000000000000000);
        _mint(0xf07901B57970bB1aC572Aa8162D2036Be617C3cc, 178000300000000000000000);
        _mint(0x3170Cb947C5199e225FDa23E1CD86b37d2E966d5, 137175200000000000000000);
        _mint(0xDf5E38Faabb01CC35E4863d45641c834318C9a06, 125000900000000000000000);
        _mint(0x22460f2C87E21898dB5C491629441E5810d98C7A, 125000300000000000000000);
        _mint(0x28202C5b73Afe5E88355D1bF4f821eDba89C8449, 102875100000000000000000);
        _mint(0x701F933E1A5d96801D24fa92f1E9D340A372a6FB, 75000400000000000000000);
        _mint(0xaf207382Fb4Eedfb12f21d07cA3902Dc9b9F3C4f, 30000100000000000000000);
        _mint(0x5A850CfB96f47A4713EF9681055df93143FB6bBA, 24192290000000000000000);
        _mint(0xE4561BF6D5017D354f9B53500FE8BDa6E7F6180C, 18000700000000000000000);
        _mint(0x805eF1C293013847Ee51D160DE2600AecdB381Ae, 5836950000000000000000);

    }

}