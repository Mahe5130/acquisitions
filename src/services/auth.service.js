import logger from '#config/logger.js';
import bcrypt from 'bcrypt';
import { eq } from 'drizzle-orm';
import { db } from '#config/database.js';
import { users } from '#models/user.model.js';

export const hashPassword = async password => {
  try {
    return await bcrypt.hash(password, 10);
  } catch (e) {
    logger.error(`Error hashing the password: ${e}`);
    throw new Error('Error hashing');
  }
};

export const comparePassword = async (password, hashedPassword) => {
  try {
    return await bcrypt.compare(password, hashedPassword);
  } catch (e) {
    logger.error(`Error comparing password: ${e}`);
    throw new Error('Error comparing password');
  }
};

export const createUser = async ({ name, email, password, role = 'user' }) => {
  try {
    const normEmail = email.trim().toLowerCase();

    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.email, normEmail))
      .limit(1);

    if (existingUser.length > 0)
      throw new Error('User with this email already exists');

    const password_hash = await hashPassword(password);

    const [newUser] = await db
      .insert(users)
      .values({
        name,
        email: normEmail,
        password: password_hash,
        role,
      })
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        created_at: users.created_at,
      });

    logger.info(`User ${newUser.email} created successfully`);
    return newUser;
  } catch (e) {
    logger.error(`Error creating the user: ${e}`);
    throw e;
  }
};

export const authenticateUser = async ({ email, password }) => {
  try {
    const normEmail = email.trim().toLowerCase();

    const [user] = await db
      .select({
        id: users.id,
        name: users.name,
        email: users.email,
        password: users.password,
        role: users.role,
        created_at: users.created_at,
      })
      .from(users)
      .where(eq(users.email, normEmail))
      .limit(1);

    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isPasswordValid = await comparePassword(password, user.password);

    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    const { password: _password, ...userWithoutPassword } = user;
    logger.info(`User ${user.email} authenticated successfully`, _password);
    return userWithoutPassword;
  } catch (e) {
    logger.error(`Error authenticating user: ${e}`);
    throw e;
  }
};
