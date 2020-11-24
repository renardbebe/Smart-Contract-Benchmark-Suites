 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.5;


library IndexedMerkleProof {
    function compute(bytes memory proof, uint160 leaf) internal pure returns (uint160 root, uint256 index) {
        uint160 computedHash = leaf;

        for (uint256 i = 0; i < proof.length / 20; i++) {
            uint160 proofElement;
             
            assembly {
                proofElement := div(mload(add(proof, add(32, mul(i, 20)))), 0x1000000000000000000000000)
            }

            if (computedHash < proofElement) {
                 
                computedHash = uint160(uint256(keccak256(abi.encodePacked(computedHash, proofElement))));
                index += (1 << i);
            } else {
                 
                computedHash = uint160(uint256(keccak256(abi.encodePacked(proofElement, computedHash))));
            }
        }

        return (computedHash, index);
    }
}

 

pragma solidity ^0.5.5;




contract InstaLend {
    using SafeMath for uint;

    address private _feesReceiver;
    uint256 private _feesPercent;
    bool private _inLendingMode;

    modifier notInLendingMode {
        require(!_inLendingMode);
        _;
    }

    constructor(address receiver, uint256 percent) public {
        _feesReceiver = receiver;
        _feesPercent = percent;
    }

    function feesReceiver() public view returns(address) {
        return _feesReceiver;
    }

    function feesPercent() public view returns(uint256) {
        return _feesPercent;
    }

    function lend(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        address target,
        bytes memory data
    )
        public
        notInLendingMode
    {
        _inLendingMode = true;

         
        uint256[] memory prevAmounts = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            prevAmounts[i] = tokens[i].balanceOf(address(this));
            require(tokens[i].transfer(target, amounts[i]));
        }

         
        (bool res,) = target.call(data);     
        require(res, "Invalid arbitrary call");

         
        for (uint i = 0; i < tokens.length; i++) {
            uint256 expectedFees = amounts[i].mul(_feesPercent).div(100);
            require(tokens[i].balanceOf(address(this)) >= prevAmounts[i].add(expectedFees));
            if (_feesReceiver != address(this)) {
                require(tokens[i].transfer(_feesReceiver, expectedFees));
            }
        }

        _inLendingMode = false;
    }
}

 

pragma solidity ^0.5.0;



 
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

 

pragma solidity ^0.5.5;




library CheckedERC20 {
    using SafeMath for uint;

    function isContract(IERC20 addr) internal view returns(bool result) {
         
        assembly {
            result := gt(extcodesize(addr), 0)
        }
    }

    function handleReturnBool() internal pure returns(bool result) {
         
        assembly {
            switch returndatasize()
            case 0 {  
                result := 1
            }
            case 32 {  
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default {  
                revert(0, 0)
            }
        }
    }

    function handleReturnBytes32() internal pure returns(bytes32 result) {
         
        assembly {
            switch eq(returndatasize(), 32)  
            case 1 {
                returndatacopy(0, 0, 32)
                result := mload(0)
            }

            switch gt(returndatasize(), 32)  
            case 1 {
                returndatacopy(0, 64, 32)
                result := mload(0)
            }

            switch lt(returndatasize(), 32)  
            case 1 {
                revert(0, 0)
            }
        }
    }

    function asmTransfer(IERC20 token, address to, uint256 value) internal returns(bool) {
        require(isContract(token));
         
        (bool res,) = address(token).call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require(res);
        return handleReturnBool();
    }

    function asmTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns(bool) {
        require(isContract(token));
         
        (bool res,) = address(token).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        require(res);
        return handleReturnBool();
    }

    function asmApprove(IERC20 token, address spender, uint256 value) internal returns(bool) {
        require(isContract(token));
         
        (bool res,) = address(token).call(abi.encodeWithSignature("approve(address,uint256)", spender, value));
        require(res);
        return handleReturnBool();
    }

     

    function checkedTransfer(IERC20 token, address to, uint256 value) internal {
        if (value > 0) {
            uint256 balance = token.balanceOf(address(this));
            asmTransfer(token, to, value);
            require(token.balanceOf(address(this)) == balance.sub(value), "checkedTransfer: Final balance didn't match");
        }
    }

    function checkedTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        if (value > 0) {
            uint256 toBalance = token.balanceOf(to);
            asmTransferFrom(token, from, to, value);
            require(token.balanceOf(to) == toBalance.add(value), "checkedTransfer: Final balance didn't match");
        }
    }
}

 

pragma solidity ^0.5.2;


contract IKyberNetwork {
    function trade(
        address src,
        uint256 srcAmount,
        address dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);

    function getExpectedRate(
        address source,
        address dest,
        uint srcQty
    )
        public
        view
        returns (
            uint expectedPrice,
            uint slippagePrice
        );
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.5;






contract AnyPaymentReceiver is Ownable {
    using SafeMath for uint256;

    address constant public ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _processPayment(
        IKyberNetwork kyber,
        address desiredToken,
        address paymentToken,
        uint256 paymentAmount
    )
        internal
        returns(uint256)
    {
        uint256 previousBalance = _balanceOf(desiredToken);

         
        if (paymentToken != address(0)) {
            require(IERC20(paymentToken).transferFrom(msg.sender, address(this), paymentAmount));
        } else {
            require(msg.value >= paymentAmount);
        }

         
        if (paymentToken != desiredToken) {
            if (paymentToken != address(0)) {
                IERC20(paymentToken).approve(address(kyber), paymentAmount);
            }

            kyber.trade.value(msg.value)(
                (paymentToken == address(0)) ? ETHER_ADDRESS : paymentToken,
                (paymentToken == address(0)) ? msg.value : paymentAmount,
                (desiredToken == address(0)) ? ETHER_ADDRESS : desiredToken,
                address(this),
                1 << 255,
                0,
                address(0)
            );
        }

        uint256 currentBalance = _balanceOf(desiredToken);
        return currentBalance.sub(previousBalance);
    }

    function _balanceOf(address token) internal view returns(uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }

    function _returnRemainder(address payable renter, IERC20 token, uint256 remainder) internal {
        if (token == IERC20(0)) {
            renter.transfer(remainder);
        } else {
            token.transfer(renter, remainder);
        }
    }
}

 

pragma solidity ^0.5.5;










contract QRToken is InstaLend, AnyPaymentReceiver {
    using SafeMath for uint;
    using ECDSA for bytes;
    using IndexedMerkleProof for bytes;
    using CheckedERC20 for IERC20;

    uint256 constant public MAX_CODES_COUNT = 1024;
    uint256 constant public MAX_WORDS_COUNT = (MAX_CODES_COUNT + 31) / 32;

    struct Distribution {
        IERC20 token;
        uint256 sumAmount;
        uint256 codesCount;
        uint256 deadline;
        address sponsor;
        uint256[32] bitMask;  
    }

    mapping(uint160 => Distribution) public distributions;

    event Created();
    event Redeemed(uint160 root, uint256 index, address receiver);

    constructor()
        public
        InstaLend(msg.sender, 1)
    {
    }

    function create(
        IERC20 token,
        uint256 sumTokenAmount,
        uint256 codesCount,
        uint160 root,
        uint256 deadline
    )
        external
        notInLendingMode
    {
        require(0 < sumTokenAmount);
        require(0 < codesCount && codesCount <= MAX_CODES_COUNT);
        require(deadline > now);

        token.checkedTransferFrom(msg.sender, address(this), sumTokenAmount);
        Distribution storage distribution = distributions[root];
        distribution.token = token;
        distribution.sumAmount = sumTokenAmount;
        distribution.codesCount = codesCount;
        distribution.deadline = deadline;
        distribution.sponsor = msg.sender;
    }

    function redeemed(uint160 root, uint index) public view returns(bool) {
        Distribution storage distribution = distributions[root];
        return distribution.bitMask[index / 32] & (1 << (index % 32)) != 0;
    }

    function calcRootAndIndex(
        bytes memory signature,
        bytes memory merkleProof,
        bytes memory message
    )
        public
        pure
        returns(uint160 root, uint256 index)
    {
        bytes32 messageHash = keccak256(message);
        bytes32 signedHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(signedHash, signature);
        uint160 signerHash = uint160(uint256(keccak256(abi.encodePacked(signer))));
        return merkleProof.compute(signerHash);
    }

    function redeem(
        bytes calldata signature,
        bytes calldata merkleProof
    )
        external
        notInLendingMode
    {
        (uint160 root, uint256 index) = calcRootAndIndex(signature, merkleProof, abi.encodePacked(msg.sender));
        Distribution storage distribution = distributions[root];
        require(distribution.bitMask[index / 32] & (1 << (index % 32)) == 0);

        distribution.bitMask[index / 32] = distribution.bitMask[index / 32] | (1 << (index % 32));
        distribution.token.checkedTransfer(msg.sender, distribution.sumAmount.div(distribution.codesCount));
        emit Redeemed(root, index, msg.sender);
    }

    function redeemWithFee(
        IKyberNetwork kyber,  
        address receiver,
        uint256 feePrecent,
        bytes calldata signature,
        bytes calldata merkleProof
    )
        external
        notInLendingMode
    {
        (uint160 root, uint256 index) = calcRootAndIndex(signature, merkleProof, abi.encodePacked(receiver, feePrecent));
        Distribution storage distribution = distributions[root];
        require(distribution.bitMask[index / 32] & (1 << (index % 32)) == 0);

        distribution.bitMask[index / 32] = distribution.bitMask[index / 32] | (1 << (index % 32));
        uint256 reward = distribution.sumAmount.div(distribution.codesCount);
        uint256 fee = reward.mul(feePrecent).div(100);
        distribution.token.checkedTransfer(receiver, reward.sub(fee));
        emit Redeemed(root, index, msg.sender);

        uint256 gotEther = _processPayment(kyber, ETHER_ADDRESS, address(distribution.token), fee);
        msg.sender.transfer(gotEther);
    }

    function abort(uint160 root)
        public
        notInLendingMode
    {
        Distribution storage distribution = distributions[root];
        require(now > distribution.deadline);

        uint256 count = 0;
        for (uint i = 0; i < 1024; i++) {
            if (distribution.bitMask[i / 32] & (1 << (i % 32)) != 0) {
                count += distribution.sumAmount / distribution.codesCount;
            }
        }
        distribution.token.checkedTransfer(distribution.sponsor, distribution.sumAmount.sub(count));
        delete distributions[root];
    }
}