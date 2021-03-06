 

 

 

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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
 

pragma solidity 0.5.7;


library AddressArrayUtils {

     
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

     
    function contains(address[] memory A, address a) internal pure returns (bool) {
        bool isIn;
        (, isIn) = indexOf(A, a);
        return isIn;
    }

     
     
    function indexOfFromEnd(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = length; i > 0; i--) {
            if (A[i - 1] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

     
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

     
    function append(address[] memory A, address a) internal pure returns (address[] memory) {
        address[] memory newAddresses = new address[](A.length + 1);
        for (uint256 i = 0; i < A.length; i++) {
            newAddresses[i] = A[i];
        }
        newAddresses[A.length] = a;
        return newAddresses;
    }

     
    function sExtend(address[] storage A, address[] storage B) internal {
        uint256 length = B.length;
        for (uint256 i = 0; i < length; i++) {
            A.push(B[i]);
        }
    }

     
    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

     
    function union(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        address[] memory leftDifference = difference(A, B);
        address[] memory rightDifference = difference(B, A);
        address[] memory intersection = intersect(A, B);
        return extend(leftDifference, extend(intersection, rightDifference));
    }

     
    function unionB(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        bool[] memory includeMap = new bool[](A.length + B.length);
        uint256 count = 0;
        for (uint256 i = 0; i < A.length; i++) {
            includeMap[i] = true;
            count++;
        }
        for (uint256 j = 0; j < B.length; j++) {
            if (!contains(A, B[j])) {
                includeMap[A.length + j] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 k = 0;
        for (uint256 m = 0; m < A.length; m++) {
            if (includeMap[m]) {
                newAddresses[k] = A[m];
                k++;
            }
        }
        for (uint256 n = 0; n < B.length; n++) {
            if (includeMap[A.length + n]) {
                newAddresses[k] = B[n];
                k++;
            }
        }
        return newAddresses;
    }

     
    function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
         
        for (uint256 i = 0; i < length; i++) {
            address e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

     
    function sReverse(address[] storage A) internal {
        address t;
        uint256 length = A.length;
        for (uint256 i = 0; i < length / 2; i++) {
            t = A[i];
            A[i] = A[A.length - i - 1];
            A[A.length - i - 1] = t;
        }
    }

     
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

     
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert();
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    function sPop(address[] storage A, uint256 index) internal returns (address) {
        uint256 length = A.length;
        if (index >= length) {
            revert("Error: index out of bounds");
        }
        address entry = A[index];
        for (uint256 i = index; i < length - 1; i++) {
            A[i] = A[i + 1];
        }
        A.length--;
        return entry;
    }

     
    function sPopCheap(address[] storage A, uint256 index) internal returns (address) {
        uint256 length = A.length;
        if (index >= length) {
            revert("Error: index out of bounds");
        }
        address entry = A[index];
        if (index != length - 1) {
            A[index] = A[length - 1];
            delete A[length - 1];
        }
        A.length--;
        return entry;
    }

     
    function sRemoveCheap(address[] storage A, address a) internal {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Error: entry not found");
        } else {
            sPopCheap(A, index);
            return;
        }
    }

     
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
            for (uint256 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

     
    function isEqual(address[] memory A, address[] memory B) internal pure returns (bool) {
        if (A.length != B.length) {
            return false;
        }
        for (uint256 i = 0; i < A.length; i++) {
            if (A[i] != B[i]) {
                return false;
            }
        }
        return true;
    }

     
    function argGet(address[] memory A, uint256[] memory indexArray)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory array = new address[](indexArray.length);
        for (uint256 i = 0; i < indexArray.length; i++) {
            array[i] = A[indexArray[i]];
        }
        return array;
    }

}

 

 

pragma solidity 0.5.7;




 
contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;

     

     
    uint256 public timeLockPeriod;

     
    mapping(bytes32 => uint256) public timeLockedUpgrades;

     

    event UpgradeRegistered(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );

     

    modifier timeLockUpgrade() {
         
         
        if (timeLockPeriod == 0) {
            _;

            return;
        }

         
         
        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );

        uint256 registrationTime = timeLockedUpgrades[upgradeHash];

         
        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;

            emit UpgradeRegistered(
                upgradeHash,
                block.timestamp
            );

            return;
        }

        require(
            block.timestamp >= registrationTime.add(timeLockPeriod),
            "TimeLockUpgrade: Time lock period must have elapsed."
        );

         
        timeLockedUpgrades[upgradeHash] = 0;

         
        _;
    }

     

     
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        external
        onlyOwner
    {
         
        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgrade: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}

 

 

pragma solidity 0.5.7;






 
contract Authorizable is
    Ownable,
    TimeLockUpgrade
{
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

     

     
    mapping (address => bool) public authorized;

     
    address[] public authorities;

     

     
    modifier onlyAuthorized {
        require(
            authorized[msg.sender],
            "Authorizable.onlyAuthorized: Sender not included in authorities"
        );
        _;
    }

     

     
    event AddressAuthorized (
        address indexed authAddress,
        address authorizedBy
    );

     
    event AuthorizedAddressRemoved (
        address indexed addressRemoved,
        address authorizedBy
    );

     

     

    function addAuthorizedAddress(address _authTarget)
        external
        onlyOwner
        timeLockUpgrade
    {
         
        require(
            !authorized[_authTarget],
            "Authorizable.addAuthorizedAddress: Address already registered"
        );

         
        authorized[_authTarget] = true;

         
        authorities.push(_authTarget);

         
        emit AddressAuthorized(
            _authTarget,
            msg.sender
        );
    }

     

    function removeAuthorizedAddress(address _authTarget)
        external
        onlyOwner
    {
         
        require(
            authorized[_authTarget],
            "Authorizable.removeAuthorizedAddress: Address not authorized"
        );

         
        authorized[_authTarget] = false;

        authorities = authorities.remove(_authTarget);

         
        emit AuthorizedAddressRemoved(
            _authTarget,
            msg.sender
        );
    }

     

     
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
         
        return authorities;
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


 
interface IERC20 {
    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address _to,
        uint256 _quantity
    )
        external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _quantity
    )
        external;

    function approve(
        address _spender,
        uint256 _quantity
    )
        external
        returns (bool);
}

 

 

pragma solidity 0.5.7;




 
library ERC20Wrapper {

     

     
    function balanceOf(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_owner);
    }

     
    function allowance(
        address _token,
        address _owner,
        address _spender
    )
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).allowance(_owner, _spender);
    }

     
    function transfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external
    {
        IERC20(_token).transfer(_to, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.transfer: Bad return value"
        );
    }

     
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external
    {
        IERC20(_token).transferFrom(_from, _to, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.transferFrom: Bad return value"
        );
    }

     
    function approve(
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        IERC20(_token).approve(_spender, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.approve: Bad return value"
        );
    }

     
    function ensureAllowance(
        address _token,
        address _owner,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        uint256 currentAllowance = allowance(_token, _owner, _spender);
        if (currentAllowance < _quantity) {
            approve(
                _token,
                _spender,
                CommonMath.maxUInt256()
            );
        }
    }

     

     
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
         
        uint256 returnValue = 0;

        assembly {
             
            switch returndatasize

             
            case 0x0 {
                returnValue := 1
            }

             
            case 0x20 {
                 
                returndatacopy(0x0, 0x0, 0x20)

                 
                returnValue := mload(0x0)
            }

             
            default { }
        }

         
        return returnValue == 1;
    }
}

 

 

pragma solidity 0.5.7;





 

contract Vault is
    Authorizable
{
     
    using SafeMath for uint256;

     

     
     
     
     
     
     
     
     
     
     
     
    mapping (address => mapping (address => uint256)) public balances;

     

     
    function withdrawTo(
        address _token,
        address _to,
        uint256 _quantity
    )
        public
        onlyAuthorized
    {
        if (_quantity > 0) {
             
            uint256 existingVaultBalance = ERC20Wrapper.balanceOf(
                _token,
                address(this)
            );

             
            ERC20Wrapper.transfer(
                _token,
                _to,
                _quantity
            );

             
            uint256 newVaultBalance = ERC20Wrapper.balanceOf(
                _token,
                address(this)
            );
             
            require(
                newVaultBalance == existingVaultBalance.sub(_quantity),
                "Vault.withdrawTo: Invalid post withdraw balance"
            );
        }
    }

     
    function incrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        public
        onlyAuthorized
    {
        if (_quantity > 0) {
             
            balances[_token][_owner] = balances[_token][_owner].add(_quantity);
        }
    }

     
    function decrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        public
        onlyAuthorized
    {
         
        require(
            balances[_token][_owner] >= _quantity,
            "Vault.decrementTokenOwner: Insufficient token balance"
        );

        if (_quantity > 0) {
             
            balances[_token][_owner] = balances[_token][_owner].sub(_quantity);
        }
    }

     

    function transferBalance(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        public
        onlyAuthorized
    {
        if (_quantity > 0) {
             
            require(
                balances[_token][_from] >= _quantity,
                "Vault.transferBalance: Insufficient token balance"
            );

             
            balances[_token][_from] = balances[_token][_from].sub(_quantity);

             
            balances[_token][_to] = balances[_token][_to].add(_quantity);
        }
    }

     
    function batchWithdrawTo(
        address[] calldata _tokens,
        address _to,
        uint256[] calldata _quantities
    )
        external
        onlyAuthorized
    {
         
        uint256 tokenCount = _tokens.length;

         
        require(
            tokenCount > 0,
            "Vault.batchWithdrawTo: Tokens must not be empty"
        );

         
        require(
            tokenCount == _quantities.length,
            "Vault.batchWithdrawTo: Tokens and quantities lengths mismatch"
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            withdrawTo(
                _tokens[i],
                _to,
                _quantities[i]
            );
        }
    }

     
    function batchIncrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external
        onlyAuthorized
    {
         
        uint256 tokenCount = _tokens.length;

         
        require(
            tokenCount > 0,
            "Vault.batchIncrementTokenOwner: Tokens must not be empty"
        );

         
        require(
            tokenCount == _quantities.length,
            "Vault.batchIncrementTokenOwner: Tokens and quantities lengths mismatch"
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            incrementTokenOwner(
                _tokens[i],
                _owner,
                _quantities[i]
            );
        }
    }

     
    function batchDecrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external
        onlyAuthorized
    {
         
        uint256 tokenCount = _tokens.length;

         
        require(
            tokenCount > 0,
            "Vault.batchDecrementTokenOwner: Tokens must not be empty"
        );

         
        require(
            tokenCount == _quantities.length,
            "Vault.batchDecrementTokenOwner: Tokens and quantities lengths mismatch"
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            decrementTokenOwner(
                _tokens[i],
                _owner,
                _quantities[i]
            );
        }
    }

     
    function batchTransferBalance(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external
        onlyAuthorized
    {
         
        uint256 tokenCount = _tokens.length;

         
        require(
            tokenCount > 0,
            "Vault.batchTransferBalance: Tokens must not be empty"
        );

         
        require(
            tokenCount == _quantities.length,
            "Vault.batchTransferBalance: Tokens and quantities lengths mismatch"
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            transferBalance(
                _tokens[i],
                _from,
                _to,
                _quantities[i]
            );
        }
    }

     
    function getOwnerBalance(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256)
    {
         
        return balances[_token][_owner];
    }
}