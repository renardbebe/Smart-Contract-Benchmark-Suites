 

pragma solidity >=0.4.22 <0.6.0;

interface NikaToken {
    function transferFrom(address from, address to, uint256 value) external;
}

contract Ethereum_Nika_Database_Service {
    NikaToken public token;

    struct VariableAmounts {
    bool isset;
    address blank_address;
    uint256 large_amount;
    uint256 large_amount2;
    string string1;
    string string2;
    string string3;
    string string4;
    string string5;
    string string6;
    string string7;
    string string8;
    }
    
    struct Ticker {
        uint256 current_slot;
        uint256 checklength;
    }

    mapping(address => mapping(uint256 => VariableAmounts)) data;
    mapping(address => Ticker) personaldata;

     constructor(
        address tokenaddress
    ) public {
        token = NikaToken(tokenaddress);
    }
    
    function return_slot() public view returns (uint256) {
        return personaldata[msg.sender].current_slot;
    }
    
    function Create_Database() public {
        token.transferFrom(msg.sender, 0x1122F0bE3077a0D915C88193Dfeee416Add1793d, 100000);
        setup();
    }
    
    modifier is_setup() {
    require(data[msg.sender][personaldata[msg.sender].current_slot].isset == true);
    _;
    }
    
     
    
    function setup() private {
        personaldata[msg.sender].current_slot = personaldata[msg.sender].checklength += 1;
        data[msg.sender][personaldata[msg.sender].current_slot] = VariableAmounts(
            true,
            msg.sender,
            0,
            0,
            "string1",
            "string2",
            "string3",
            "string4",
            "string5",
            "string6",
            "string7",
            "string8"
        );
    }
    
    function Choose_Your_Slot(uint256 Slot) public returns (uint256) {
        personaldata[msg.sender].current_slot = Slot;
        return personaldata[msg.sender].current_slot;
    }
    
    function Edit_Only_Address(address new_address) public is_setup {
        VariableAmounts storage s = data[msg.sender][personaldata[msg.sender].current_slot];
        s.blank_address = new_address;
    }
    
    function Edit_Only_Numbers(uint256 first_number, uint256 second_number) public is_setup {
        VariableAmounts storage s = data[msg.sender][personaldata[msg.sender].current_slot];
        s.large_amount = first_number;
        s.large_amount2 = second_number;
    }
    
    
    function Edit_Strings_1_through_2(
    string string_pass1,
    string string_pass2
    ) public is_setup {
    data[msg.sender][personaldata[msg.sender].current_slot].string1 = string_pass1;
    data[msg.sender][personaldata[msg.sender].current_slot].string2 = string_pass2;
    }
    
    function Edit_Strings_3_through_4(
    string string_pass3,
    string string_pass4
    ) public is_setup {
    VariableAmounts storage s = data[msg.sender][personaldata[msg.sender].current_slot];
    s.string3 = string_pass3;
    s.string4 = string_pass4;
    }
    
    function Edit_Strings_5_through_6(
    string string_pass5,
    string string_pass6
    ) public is_setup {
    VariableAmounts storage s = data[msg.sender][personaldata[msg.sender].current_slot];
    s.string5 = string_pass5;
    s.string6 = string_pass6;
    }
    
    function Edit_Strings_7_through_8(
    string string_pass7,
    string string_pass8
    ) public is_setup {
    VariableAmounts storage s = data[msg.sender][personaldata[msg.sender].current_slot];
    s.string7 = string_pass7;
    s.string8 = string_pass8;
    }
    
     
    
    function Return_Address() public view returns (address) {
       return data[msg.sender][personaldata[msg.sender].current_slot].blank_address;
    }
    
    function Return_Number1() public view returns (uint256) {
       return data[msg.sender][personaldata[msg.sender].current_slot].large_amount;
    }
    
    function Return_Number2() public view returns (uint256) {
       return data[msg.sender][personaldata[msg.sender].current_slot].large_amount2;
    }
    
    function Return_String1() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string1;
    }
    
    function Return_String2() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string2;
    }
    
    function Return_String3() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string3;
    }
    
    function Return_String4() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string4;
    }
    
    function Return_String5() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string5;
    }
    
    function Return_String6() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string6;
    }
    
    function Return_String7() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string7;
    }
    
    function Return_String8() public view returns (string) {
       return data[msg.sender][personaldata[msg.sender].current_slot].string8;
    }
    
    
}