import { UserModel } from "./user";
import { AuthenticatedUser } from "../lib/auth";

describe("user model", () => {

  it("sets default values", () => {
    const user = UserModel.create({});
    expect(user.authenticated).toBe(false);
    expect(user.name).toBe("Anonymous User");
    expect(user.className).toBe("");
    expect(user.group).toBe(null);
    expect(user.id).toBe(null);
  });

  it("uses override values", () => {
    const user = UserModel.create({
        authenticated: true,
        name: "Test User",
        className: "Test Class",
        group: "1",
        id: "2",
    });
    expect(user.authenticated).toBe(true);
    expect(user.name).toBe("Test User");
    expect(user.className).toBe("Test Class");
    expect(user.group).toBe("1");
    expect(user.id).toBe("2");
  });

  it("can change its name", () => {
    const user = UserModel.create({
        name: "Test User",
    });
    expect(user.name).toBe("Test User");
    user.setName("Different User");
    expect(user.name).toBe("Different User");
  });

  it("can authenticate", () => {
    const user = UserModel.create();
    user.setAuthenticated(true);
    expect(user.authenticated).toBe(true);
  });

  it("can set a class name", () => {
    const user = UserModel.create();
    const className = "test class";
    user.setClassName(className);
    expect(user.className).toBe(className);
  });

  it("can set a group", () => {
    const user = UserModel.create();
    const group = "1";
    user.setGroup(group);
    expect(user.group).toBe(group);
  });

  it("can set an id", () => {
    const user = UserModel.create();
    const id = "1";
    user.setId(id);
    expect(user.id).toBe(id);
  });

  it("can set an authenticated user", () => {
    const user = UserModel.create();
    const authenticatedUser: AuthenticatedUser = {
      type: "student",
      id: "1",
      firstName: "Fred",
      lastName: "Flintstone",
      fullName: "Fred Flintstone",
      initials: "FF",
      className: "Bedrock",
    };
    user.setAuthenticatedUser(authenticatedUser);
    expect(user.authenticated).toBe(true);
    expect(user.id).toBe(authenticatedUser.id);
    expect(user.name).toBe(authenticatedUser.fullName);
    expect(user.className).toBe(authenticatedUser.className);
    expect(user.group).toBe(null);
  });
});
