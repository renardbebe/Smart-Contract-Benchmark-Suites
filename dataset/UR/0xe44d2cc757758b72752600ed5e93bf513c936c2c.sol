 

 

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

        for (uint256 i = 0; i < proof.length; i++) {
            uint160 proofElement;
             
            assembly {
                proofElement := div(mload(add(proof, 32)), 0x1000000000000000000000000)
            }

            if (computedHash < proofElement) {
                 
                computedHash = uint160(uint256(keccak256(abi.encodePacked(computedHash, proofElement))));
                index |= (1 << i);
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

 

pragma solidity ^0.5.5;







contract QRToken is InstaLend {
    using SafeMath for uint;
    using ECDSA for bytes;
    using IndexedMerkleProof for bytes;

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

        require(token.transferFrom(msg.sender, address(this), sumTokenAmount));
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

    function redeem(
        bytes calldata signature,
        bytes calldata merkleProof
    )
        external
        notInLendingMode
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
        address signer = ECDSA.recover(messageHash, signature);
        (uint160 root, uint256 index) = merkleProof.compute(uint160(signer));
        Distribution storage distribution = distributions[root];
        require(distribution.bitMask[index / 32] & (1 << (index % 32)) == 0);

        distribution.bitMask[index / 32] = distribution.bitMask[index / 32] | (1 << (index % 32));
        require(distribution.token.transfer(msg.sender, distribution.sumAmount.div(distribution.codesCount)));
        emit Redeemed(root, index, msg.sender);
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
        require(distribution.token.transfer(distribution.sponsor, distribution.sumAmount.sub(count)));
        delete distributions[root];
    }
}