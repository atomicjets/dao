import "../../../dao-stl/src/assertions/DaoAsserter.sol";
import "../src/AbstractMintedCurrency.sol";

contract AbstractMintedCurrencyImpl is AbstractMintedCurrency {

    function AbstractMintedCurrencyImpl(address currencyDatabase, address minter)
        AbstractMintedCurrency(currencyDatabase, minter) {}

    function mint(address receiver, uint amount) returns (uint16 error) {}

    function send(address receiver, uint amount) returns (uint16 error) {}

}

contract AbstractMintedCurrencyTest is DaoAsserter {

    address constant TEST_ADDRESS = 0x12345;
    address constant TEST_ADDRESS_2 = 0x54321;

    function testSetMinterSuccess() {
        var dmc = new AbstractMintedCurrencyImpl(0, this);
        var err = dmc.setMinter(TEST_ADDRESS);
        assertNoError(err, "setMinter returned error");
        var minter = dmc.minter();
        assertAddressesEqual(dmc.minter(), TEST_ADDRESS, "minter returns the wrong address");
    }

    function testSetMinterFailAccessDenied() {
        var dmc = new AbstractMintedCurrencyImpl(0, TEST_ADDRESS);
        var err = dmc.setMinter(TEST_ADDRESS_2);
        assertErrorsEqual(err, ACCESS_DENIED, "setMinter returned no 'access denied' error");
        assertAddressesEqual(dmc.minter(), TEST_ADDRESS, "minter returns the wrong address");
    }

    function testSetCurrencyDatabaseSuccess() {
        var dmc = new AbstractMintedCurrencyImpl(0, this);
        var err = dmc.setCurrencyDatabase(TEST_ADDRESS);
        assertNoError(err, "setCurrencyDatabase returned an error");
        var cd = dmc.currencyDatabase();
        assertAddressesEqual(cd, TEST_ADDRESS, "currencyDatabase returns the wrong address");
    }

    function testSetCurrencyDatabaseFailNotMinter() {
        var dmc = new AbstractMintedCurrencyImpl(TEST_ADDRESS, TEST_ADDRESS_2);
        var err = dmc.setCurrencyDatabase(this);
        assertErrorsEqual(err, ACCESS_DENIED, "setCurrencyDatabase did not return 'access denied' error");
        var cd = dmc.currencyDatabase();
        assertAddressesEqual(cd, TEST_ADDRESS, "currencyDatabase returns the wrong address");
    }

}