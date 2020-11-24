 

pragma solidity ^0.4.24;

library AZTECInterface {
    function validateJoinSplit(bytes32[6][], uint, uint, bytes32[4]) external pure returns (bool) {}
}

 
contract AZTEC {
     
    function() external payable {
        assembly {

             
             
            validateJoinSplit()

             
            mstore(0x00, 404)
            revert(0x00, 0x20)

             
            function validateJoinSplit() {
                mstore(0x80, 7673901602397024137095011250362199966051872585513276903826533215767972925880)  
                mstore(0xa0, 8489654445897228341090914135473290831551238522473825886865492707826370766375)  
                let notes := add(0x04, calldataload(0x04))
                let m := calldataload(0x24)
                let n := calldataload(notes)
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let challenge := mod(calldataload(0x44), gen_order)

                 
                if gt(m, n) { mstore(0x00, 404) revert(0x00, 0x20) }

                 
                let kn := calldataload(sub(calldatasize, 0xc0))

                 
                mstore(0x2a0, caller)
                mstore(0x2c0, kn)
                mstore(0x2e0, m)
                kn := mulmod(sub(gen_order, kn), challenge, gen_order)  
                hashCommitments(notes, n)
                let b := add(0x300, mul(n, 0x80))

                 
                 
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {

                     
                    let noteIndex := add(add(notes, 0x20), mul(i, 0xc0))

                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                    let k
                    let a := calldataload(add(noteIndex, 0x20))
                    let c := challenge

                     
                     
                     
                     
                     
                    switch eq(add(i, 0x01), n)
                    case 1 {
                        k := kn

                         
                        if eq(m, n) {
                            k := sub(gen_order, k)
                        }
                    }
                    case 0 { k := calldataload(noteIndex) }

                     
                    validateCommitment(noteIndex, k, a)

                     
                     
                    switch gt(add(i, 0x01), m)
                    case 1 {

                         
                        kn := addmod(kn, sub(gen_order, k), gen_order)
                        let x := mod(mload(0x00), gen_order)
                        k := mulmod(k, x, gen_order)
                        a := mulmod(a, x, gen_order)
                        c := mulmod(challenge, x, gen_order)

                         
                        mstore(0x00, keccak256(0x00, 0x20))
                    }
                    case 0 {

                         
                        kn := addmod(kn, k, gen_order)
                    }
                    
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                    calldatacopy(0xe0, add(noteIndex, 0x80), 0x40)
                    calldatacopy(0x20, add(noteIndex, 0x40), 0x40)
                    mstore(0x120, sub(gen_order, c)) 
                    mstore(0x60, k)
                    mstore(0xc0, a)

                     
                     
                     
                     
                     
                    let result := staticcall(gas, 7, 0xe0, 0x60, 0x1a0, 0x40)
                    result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x120, 0x40))
                    result := and(result, staticcall(gas, 7, 0x80, 0x60, 0x160, 0x40))

                     
                     
                     
                    result := and(result, staticcall(gas, 6, 0x120, 0x80, 0x160, 0x40))

                     
                     
                    result := and(result, staticcall(gas, 6, 0x160, 0x80, b, 0x40))

                     
                     
                     
                     
                    if eq(i, m) {
                        mstore(0x260, mload(0x20))
                        mstore(0x280, mload(0x40))
                        mstore(0x1e0, mload(0xe0))
                        mstore(0x200, sub(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47, mload(0x100)))
                    }

                     
                     
                     
                    if gt(i, m) {
                       mstore(0x60, c)
                       result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x220, 0x40))

                        
                       result := and(result, staticcall(gas, 6, 0x220, 0x80, 0x260, 0x40))

                        
                       result := and(result, staticcall(gas, 6, 0x1a0, 0x80, 0x1e0, 0x40))
                    }

                     
                    if iszero(result) { mstore(0x00, 400) revert(0x00, 0x20) }
                    b := add(b, 0x40)  
                }

                 
                 
                 
                if lt(m, n) {
                   validatePairing(0x64)
                }

                 
                 
                 
                let expected := mod(keccak256(0x2a0, sub(b, 0x2a0)), gen_order)
                if iszero(eq(expected, challenge)) {

                     
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }

                 
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }

             
            function validatePairing(t2) {
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let t2_x_1 := calldataload(t2)
                let t2_x_2 := calldataload(add(t2, 0x20))
                let t2_y_1 := calldataload(add(t2, 0x40))
                let t2_y_2 := calldataload(add(t2, 0x60))

                 
                if or(or(or(or(or(or(or(
                    iszero(t2_x_1),
                    iszero(t2_x_2)),
                    iszero(t2_y_1)),
                    iszero(t2_y_2)),
                    eq(t2_x_1, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)),
                    eq(t2_x_2, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)),
                    eq(t2_y_1, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)),
                    eq(t2_y_2, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b))
                {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }

                 
                 
                 
                mstore(0x20, mload(0x1e0))  
                mstore(0x40, mload(0x200))  
                mstore(0x80, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
                mstore(0x60, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)
                mstore(0xc0, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)
                mstore(0xa0, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
                mstore(0xe0, mload(0x260))  
                mstore(0x100, mload(0x280))  
                mstore(0x140, t2_x_1)
                mstore(0x120, t2_x_2)
                mstore(0x180, t2_y_1)
                mstore(0x160, t2_y_2)

                let success := staticcall(gas, 8, 0x20, 0x180, 0x20, 0x20)

                if or(iszero(success), iszero(mload(0x20))) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

             
            function validateCommitment(note, k, a) {
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let gammaX := calldataload(add(note, 0x40))
                let gammaY := calldataload(add(note, 0x60))
                let sigmaX := calldataload(add(note, 0x80))
                let sigmaY := calldataload(add(note, 0xa0))
                if iszero(
                    and(
                        and(
                            and(
                                eq(mod(a, gen_order), a),  
                                gt(a, 1)                   
                            ),
                            and(
                                eq(mod(k, gen_order), k),  
                                gt(k, 1)                   
                            )
                        ),
                        and(
                            eq(  
                                addmod(mulmod(mulmod(sigmaX, sigmaX, field_order), sigmaX, field_order), 3, field_order),
                                mulmod(sigmaY, sigmaY, field_order)
                            ),
                            eq(  
                                addmod(mulmod(mulmod(gammaX, gammaX, field_order), gammaX, field_order), 3, field_order),
                                mulmod(gammaY, gammaY, field_order)
                            )
                        )
                    )
                ) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

             
            function hashCommitments(notes, n) {
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {
                    let index := add(add(notes, mul(i, 0xc0)), 0x60)
                    calldatacopy(add(0x300, mul(i, 0x80)), index, 0x80)
                }
                mstore(0x00, keccak256(0x300, mul(n, 0x80)))
            }
        }
    }
}

 
contract ERC20Interface {
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);
}

 
contract AZTECERC20Bridge {
    bytes32[4] setupPubKey;
    bytes32 domainHash;
    uint private constant groupModulusBoundary = 10944121435919637611123202872628637544274182200208017171849102093287904247808;
    uint private constant groupModulus = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint public scalingFactor;
    mapping(bytes32 => address) public noteRegistry;
    ERC20Interface token;

    event Created(bytes32 domainHash, address contractAddress);
    event ConfidentialTransfer();

     
    constructor(bytes32[4] _setupPubKey, address _token, uint256 _scalingFactor, uint256 _chainId) public {
        setupPubKey = _setupPubKey;
        token = ERC20Interface(_token);
        scalingFactor = _scalingFactor;
        bytes32 _domainHash;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)  
            mstore(add(m, 0x20), 0x60d177492a60de7c666b3e3d468f14d59def1d4b022d08b6adf554d88da60d63)  
            mstore(add(m, 0x40), 0x28a43689b8932fb9695c28766648ed3d943ff8a6406f8f593738feed70039290)  
            mstore(add(m, 0x60), _chainId)  
            mstore(add(m, 0x80), address)  
            _domainHash := keccak256(m, 0xa0)
        }
        domainHash = _domainHash;
        emit Created(_domainHash, this);
    }

     
    function validateInputNote(bytes32[6] note, bytes32[3] signature, uint challenge, bytes32 domainHashT) internal {
        bytes32 noteHash;
        bytes32 signatureMessage;
        assembly {
            let m := mload(0x40)
            mstore(m, mload(add(note, 0x40)))
            mstore(add(m, 0x20), mload(add(note, 0x60)))
            mstore(add(m, 0x40), mload(add(note, 0x80)))
            mstore(add(m, 0x60), mload(add(note, 0xa0)))
            noteHash := keccak256(m, 0x80)
            mstore(m, 0x0f1ea84c0ceb3ad2f38123d94a164612e1a0c14a694dc5bfa16bc86ea1f3eabd)  
            mstore(add(m, 0x20), noteHash)
            mstore(add(m, 0x40), challenge)
            mstore(add(m, 0x60), caller)
            mstore(add(m, 0x40), keccak256(m, 0x80))
            mstore(add(m, 0x20), domainHashT)
            mstore(m, 0x1901)
            signatureMessage := keccak256(add(m, 0x1e), 0x42)
        }
        address owner = ecrecover(signatureMessage, uint8(signature[0]), signature[1], signature[2]);
        require(owner != address(0), "signature invalid");
        require(noteRegistry[noteHash] == owner, "expected input note to exist in registry");
        noteRegistry[noteHash] = 0;
    }

     
    function validateOutputNote(bytes32[6] note, address owner) internal {
        bytes32 noteHash;  
        assembly {
            let m := mload(0x40)
            mstore(m, mload(add(note, 0x40)))
            mstore(add(m, 0x20), mload(add(note, 0x60)))
            mstore(add(m, 0x40), mload(add(note, 0x80)))
            mstore(add(m, 0x60), mload(add(note, 0xa0)))
            noteHash := keccak256(m, 0x80)
        }
        require(owner != address(0), "owner must be valid Ethereum address");
        require(noteRegistry[noteHash] == 0, "expected output note to not exist in registry");
        noteRegistry[noteHash] = owner;
    }

     
    function confidentialTransfer(bytes32[6][] notes, uint256 m, uint256 challenge, bytes32[3][] inputSignatures, address[] outputOwners, bytes) external {
        require(inputSignatures.length == m, "input signature length invalid");
        require(inputSignatures.length + outputOwners.length == notes.length, "array length mismatch");

         
        require(AZTECInterface.validateJoinSplit(notes, m, challenge, setupPubKey), "proof not valid!");

         
        uint256 kPublic = uint(notes[notes.length - 1][0]);
        require(kPublic < groupModulus, "invalid value of kPublic");

         
        for (uint256 i = 0; i < notes.length; i++) {

             
            if (i < m) {

                 
                 
                 
                validateInputNote(notes[i], inputSignatures[i], challenge, domainHash);
            } else {

                 
                 
                 
                validateOutputNote(notes[i], outputOwners[i - m]);
            }
        }

        if (kPublic > 0) {
            if (kPublic < groupModulusBoundary) {

                 
                 
                require(token.transfer(msg.sender, kPublic * scalingFactor), "token transfer to user failed!");
            } else {

                 
                 
                require(token.transferFrom(msg.sender, this, (groupModulus - kPublic) * scalingFactor), "token transfer from user failed!");
            }
        }

         
        emit ConfidentialTransfer();
    }
}