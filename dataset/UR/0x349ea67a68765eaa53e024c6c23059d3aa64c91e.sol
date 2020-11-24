 

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;


 
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;



 
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
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

 

pragma solidity 0.5.7;


library CommonValidationsLibrary {

     
    function validateNonEmpty(
        address[] calldata _addressArray
    )
        external
        pure
    {
        require(
            _addressArray.length > 0,
            "Address array length must be > 0"
        );
    }

     
    function validateEqualLength(
        address[] calldata _addressArray,
        uint256[] calldata _uint256Array
    )
        external
        pure
    {
        require(
            _addressArray.length == _uint256Array.length,
            "Input length mismatch"
        );
    }
}

 

 

pragma solidity 0.5.7;



library CommonMath {
    using SafeMath for uint256;

     
    function maxUInt256()
        internal
        pure
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

     
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0);

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

             
            result = previousResult.mul(a);
        }

        return result;
    }

     
    function getPartialAmount(
        uint256 _principal,
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256)
    {
         
        uint256 remainder = mulmod(_principal, _numerator, _denominator);

         
        if (remainder == 0) {
            return _principal.mul(_numerator).div(_denominator);
        }

         
        uint256 errPercentageTimes1000000 = remainder.mul(1000000).div(_numerator.mul(_principal));

         
        require(
            errPercentageTimes1000000 < 1000,
            "CommonMath.getPartialAmount: Rounding error exceeds bounds"
        );

        return _principal.mul(_numerator).div(_denominator);
    }

}

 

 

pragma solidity 0.5.7;


 
interface ISetFactory {

     

     
    function core()
        external
        returns (address);

     
    function createSet(
        address[] calldata _components,
        uint[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);
}

 

 

pragma solidity 0.5.7;








 
contract SetToken is
    ERC20,
    ERC20Detailed
{
    using SafeMath for uint256;

     

    uint256 public naturalUnit;
    address[] public components;
    uint256[] public units;

     
    mapping(address => bool) internal isComponent;

     
    address public factory;

     

     
    constructor(
        address _factory,
        address[] memory _components,
        uint256[] memory _units,
        uint256 _naturalUnit,
        string memory _name,
        string memory _symbol
    )
        public
        ERC20Detailed(
            _name,
            _symbol,
            18
        )
    {
         
        uint256 unitCount = _units.length;

         
        require(
            _naturalUnit > 0,
            "SetToken.constructor: Natural unit must be positive"
        );

         
        CommonValidationsLibrary.validateNonEmpty(_components);

         
        CommonValidationsLibrary.validateEqualLength(_components, _units);

         
         
        uint8 minDecimals = 18;
        uint8 currentDecimals;
        for (uint256 i = 0; i < unitCount; i++) {
             
            uint256 currentUnits = _units[i];
            require(
                currentUnits > 0,
                "SetToken.constructor: Units must be positive"
            );

             
            address currentComponent = _components[i];
            require(
                currentComponent != address(0),
                "SetToken.constructor: Invalid component address"
            );

             
             
            (bool success, ) = currentComponent.call(abi.encodeWithSignature("decimals()"));
            if (success) {
                currentDecimals = ERC20Detailed(currentComponent).decimals();
                minDecimals = currentDecimals < minDecimals ? currentDecimals : minDecimals;
            } else {
                 
                 
                minDecimals = 0;
            }

             
            require(
                !tokenIsComponent(currentComponent),
                "SetToken.constructor: Duplicated component"
            );

             
            isComponent[currentComponent] = true;

             
            components.push(currentComponent);
            units.push(currentUnits);
        }

         
        require(
            _naturalUnit >= CommonMath.safePower(10, uint256(18).sub(minDecimals)),
            "SetToken.constructor: Invalid natural unit"
        );

        factory = _factory;
        naturalUnit = _naturalUnit;
    }

     

     
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external
    {
         
        require(
            msg.sender == ISetFactory(factory).core(),
            "SetToken.mint: Sender must be core"
        );

        _mint(_issuer, _quantity);
    }

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external
    {
         
        require(
            msg.sender == ISetFactory(factory).core(),
            "SetToken.burn: Sender must be core"
        );

        _burn(_from, _quantity);
    }

     
    function getComponents()
        external
        view
        returns (address[] memory)
    {
        return components;
    }

     
    function getUnits()
        external
        view
        returns (uint256[] memory)
    {
        return units;
    }

     
    function tokenIsComponent(
        address _tokenAddress
    )
        public
        view
        returns (bool)
    {
        return isComponent[_tokenAddress];
    }
}